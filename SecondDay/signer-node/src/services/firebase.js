const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    this.db = null;
    this.initialized = false;
  }

  initialize() {
    if (this.initialized) return this.db;

    try {
      const serviceAccount = {
        type: "service_account",
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: "37d9e726d982aa228057844800e268cce06024a6",
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: "114401495163225626947",
        auth_uri: "https://accounts.google.com/o/oauth2/auth",
        token_uri: "https://oauth2.googleapis.com/token",
        auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
        client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`,
        universe_domain: "googleapis.com"
      };

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID
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
