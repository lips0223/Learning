const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    this.db = null;
    this.initialized = false;
  }

  initialize() {
    if (this.initialized) return this.db;

    try {
      // 处理 Firebase 私钥
      let privateKey = process.env.FIREBASE_PRIVATE_KEY;
      if (privateKey) {
        console.log('🔍 Raw private key length:', privateKey.length);
        console.log('🔍 Raw private key first 50 chars:', privateKey.substring(0, 50));
        console.log('🔍 Contains literal \\n:', privateKey.includes('\\n'));
        
        // 处理 Vercel 可能添加的外层引号
        if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
          privateKey = privateKey.slice(1, -1);
          console.log('✅ Removed outer quotes from private key');
        }
        
        // 处理转义的换行符
        if (privateKey.includes('\\n')) {
          privateKey = privateKey.replace(/\\n/g, '\n');
          console.log('✅ Converted literal \\n to newlines');
        }
        
        // 处理可能的双重转义
        if (privateKey.includes('\\"')) {
          privateKey = privateKey.replace(/\\"/g, '"');
          console.log('✅ Converted escaped quotes');
        }
        
        console.log('🔍 Final private key length:', privateKey.length);
        console.log('🔍 Starts with BEGIN:', privateKey.startsWith('-----BEGIN PRIVATE KEY-----'));
        console.log('🔍 Ends with END:', privateKey.endsWith('-----END PRIVATE KEY-----'));
      } else {
        console.log('❌ FIREBASE_PRIVATE_KEY not found in environment variables');
      }

      // 验证必要的环境变量
      if (!process.env.FIREBASE_PROJECT_ID) {
        throw new Error('FIREBASE_PROJECT_ID environment variable is required');
      }
      if (!process.env.FIREBASE_PRIVATE_KEY) {
        throw new Error('FIREBASE_PRIVATE_KEY environment variable is required');
      }
      if (!process.env.FIREBASE_CLIENT_EMAIL) {
        throw new Error('FIREBASE_CLIENT_EMAIL environment variable is required');
      }

      console.log('🔑 Firebase config validation passed');

      // 使用更简单的初始化方式
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey
        })
      });

      this.db = admin.firestore();
      this.initialized = true;
      console.log('✅ Firebase Admin SDK initialized successfully');
      return this.db;
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error);
      throw error;
    }
  }

  async saveSignature(signatureData) {
    const db = this.initialize();
    
    try {
      const sigRef = await db.collection('signatures').add({
        ...signatureData,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 更新用户的签名计数（如果用户存在）
      try {
        const userRef = db.collection('users').doc(signatureData.userAddress.toLowerCase());
        await userRef.update({
          signatureCount: admin.firestore.FieldValue.increment(1),
          lastSignatureAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } catch (userError) {
        // 如果用户不存在，创建用户
        await this.createUser({
          address: signatureData.userAddress,
          signatureCount: 1
        });
      }

      return { id: sigRef.id, ...signatureData };
    } catch (error) {
      console.error('Error saving signature:', error);
      throw error;
    }
  }

  async getUser(address) {
    const db = this.initialize();
    
    try {
      const userDoc = await db.collection('users').doc(address.toLowerCase()).get();
      if (userDoc.exists) {
        return { id: userDoc.id, ...userDoc.data() };
      }
      return null;
    } catch (error) {
      console.error('Error getting user:', error);
      throw error;
    }
  }

  async createUser(userData) {
    const db = this.initialize();
    
    try {
      const address = userData.address.toLowerCase();
      const userRef = db.collection('users').doc(address);
      
      const newUser = {
        address: address,
        originalAddress: userData.address,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        signatureCount: userData.signatureCount || 0,
        ...userData
      };

      await userRef.set(newUser);
      return { id: address, ...newUser };
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  async getUserSignatures(address) {
    const db = this.initialize();
    
    try {
      const signaturesQuery = await db
        .collection('signatures')
        .where('userAddress', '==', address.toLowerCase())
        .orderBy('createdAt', 'desc')
        .get();

      return signaturesQuery.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error('Error getting user signatures:', error);
      throw error;
    }
  }
}

// 导出单例实例
module.exports = new FirebaseService();
