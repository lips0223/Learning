module.exports = (req, res) => {
  // 打印环境变量信息到控制台
  console.log('=== Environment Variables Debug ===');
  console.log('FIREBASE_PROJECT_ID:', process.env.FIREBASE_PROJECT_ID);
  console.log('FIREBASE_CLIENT_EMAIL:', process.env.FIREBASE_CLIENT_EMAIL);
  console.log('FIREBASE_PRIVATE_KEY exists:', !!process.env.FIREBASE_PRIVATE_KEY);
  console.log('FIREBASE_PRIVATE_KEY length:', process.env.FIREBASE_PRIVATE_KEY?.length || 0);
  console.log('FIREBASE_PRIVATE_KEY first 100 chars:', process.env.FIREBASE_PRIVATE_KEY?.substring(0, 100));
  console.log('FIREBASE_PRIVATE_KEY last 100 chars:', process.env.FIREBASE_PRIVATE_KEY?.substring(-100));
  console.log('===================================');
  
  res.json({ 
    message: 'Debug version with detailed env vars - Serverless Function',
    timestamp: new Date().toISOString(),
    env: {
      hasPrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
      privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length || 0,
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKeyStart: process.env.FIREBASE_PRIVATE_KEY?.substring(0, 50),
      privateKeyEnd: process.env.FIREBASE_PRIVATE_KEY?.substring(-50)
    }
  });
};