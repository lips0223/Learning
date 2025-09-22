const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件配置
app.use(helmet()); // 安全头

// CORS 配置 - 允许所有来源访问
app.use(cors({
  origin: '*', // 允许所有来源
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: false // 由于允许所有来源，不能使用credentials
}));

app.use(morgan('combined')); // 日志
app.use(express.json({ limit: '10mb' })); // JSON 解析
app.use(express.urlencoded({ extended: true }));

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'TokenAirDrop Signer Service'
  });
});

// API 路由
app.use('/api/signatures', require('./routes/signatures'));

// 临时 API 端点用于测试
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working!', timestamp: new Date().toISOString() });
});

// 环境变量测试端点
app.get('/api/test-env', (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    env_check: {
      hasFirebaseProjectId: !!process.env.FIREBASE_PROJECT_ID,
      hasFirebasePrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
      hasFirebaseClientEmail: !!process.env.FIREBASE_CLIENT_EMAIL,
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length || 0,
      privateKeyFirst30: process.env.FIREBASE_PRIVATE_KEY?.substring(0, 30) || 'NOT_FOUND'
    }
  });
});

// Firebase 测试端点
app.get('/api/test-firebase', async (req, res) => {
  try {
    const { initializeFirebase } = require('./services/firebase');
    const result = await initializeFirebase();
    
    res.json({
      timestamp: new Date().toISOString(),
      firebase_status: 'initialized',
      config_check: {
        hasFirebaseProjectId: !!process.env.FIREBASE_PROJECT_ID,
        hasFirebasePrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
        hasFirebaseClientEmail: !!process.env.FIREBASE_CLIENT_EMAIL,
        privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length || 0
      },
      result
    });
  } catch (error) {
    res.status(500).json({
      timestamp: new Date().toISOString(),
      firebase_status: 'error',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`🚀 Signer Service running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`🔥 Firebase Project: ${process.env.FIREBASE_PROJECT_ID}`);
});

module.exports = app;
