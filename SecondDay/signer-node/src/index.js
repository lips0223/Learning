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
  const envCheck = {
    message: 'API is working!',
    timestamp: new Date().toISOString(),
    env: {
      hasFirebaseProjectId: !!process.env.FIREBASE_PROJECT_ID,
      hasFirebasePrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
      hasFirebaseClientEmail: !!process.env.FIREBASE_CLIENT_EMAIL,
      firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'NOT_SET',
      privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length || 0,
      privateKeyStartsWith: process.env.FIREBASE_PRIVATE_KEY?.startsWith('-----BEGIN') || false
    }
  };
  res.json(envCheck);
});

// 调试端点 - 检查环境变量状态（不暴露具体内容）
app.get('/api/debug/env-status', (req, res) => {
  try {
    const envStatus = {
      hasFirebaseProjectId: !!process.env.FIREBASE_PROJECT_ID,
      hasFirebasePrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
      hasFirebaseClientEmail: !!process.env.FIREBASE_CLIENT_EMAIL,
      hasSignerPrivateKey: !!process.env.SIGNER_PRIVATE_KEY,
      firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'NOT_SET',
      firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL || 'NOT_SET',
      privateKeyLength: process.env.FIREBASE_PRIVATE_KEY?.length || 0,
      privateKeyStartsWith: process.env.FIREBASE_PRIVATE_KEY?.substring(0, 30) || 'NOT_SET',
      timestamp: new Date().toISOString()
    };
    res.json(envStatus);
  } catch (error) {
    res.status(500).json({ error: error.message });
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
