# TokenAirDrop Signer Service 后端集成文档

## 目录

1. [项目概述](#项目概述)
2. [技术栈](#技术栈)
3. [项目结构](#项目结构)
4. [Firebase 集成](#firebase-集成)
5. [Vercel 部署](#vercel-部署)
6. [代码架构详解](#代码架构详解)
7. [环境配置](#环境配置)
8. [开发指南](#开发指南)
9. [故障排查](#故障排查)

## 项目概述

TokenAirDrop Signer Service 是一个基于 Node.js + Express 的后端 API 服务，专门用于生成和验证 TokenAirDrop 合约的签名。该服务集成了 Firebase Firestore 数据库和 Vercel 云部署平台。

### 核心功能
- 🔐 生成 EIP-712 标准签名
- ✅ 验证签名有效性
- 🗄️ Firebase Firestore 数据持久化
- 🌐 跨域支持
- ☁️ Vercel 云部署
- 📊 健康检查和监控

## 技术栈

### 后端框架
- **Node.js**: v18+ 运行时环境
- **Express.js**: v5.1.0 Web 框架
- **ethers.js**: v6.15.0 以太坊交互库

### 数据库
- **Firebase Firestore**: NoSQL 云数据库
- **firebase-admin**: v13.5.0 管理 SDK

### 部署平台
- **Vercel**: Serverless 部署平台
- **GitHub**: 代码仓库和 CI/CD

### 安全和中间件
- **helmet**: v8.1.0 安全头部
- **cors**: v2.8.5 跨域资源共享
- **morgan**: v1.10.1 HTTP 请求日志
- **dotenv**: v17.2.2 环境变量管理

## 项目结构

```
signer-node/
├── src/
│   ├── index.js                 # 主应用入口
│   ├── controllers/
│   │   └── signatures.js        # 签名控制器
│   ├── services/
│   │   ├── signer.js            # 签名服务
│   │   └── firebase.js          # Firebase 服务
│   └── routes/
│       └── signatures.js        # 路由定义
├── .env                         # 环境变量（本地）
├── .gitignore                   # Git 忽略文件
├── package.json                 # 项目配置
├── vercel.json                  # Vercel 部署配置
├── API.md                       # API 文档
└── BACKEND_INTEGRATION.md       # 本文档
```

## Firebase 集成

### 1. Firebase 项目设置

#### 创建 Firebase 项目
```bash
# 1. 访问 https://console.firebase.google.com/
# 2. 点击 "创建项目"
# 3. 项目名称: token-airdrop-signer
# 4. 启用 Google Analytics（可选）
```

#### 启用 Firestore 数据库
```bash
# 1. 在 Firebase 控制台选择 "Firestore Database"
# 2. 点击 "创建数据库"
# 3. 选择 "生产模式"
# 4. 选择数据库位置（推荐 asia-east1）
```

### 2. 服务账号配置

#### 生成服务账号密钥
```bash
# 1. Firebase 控制台 → 项目设置 → 服务账号
# 2. 点击 "生成新的私钥"
# 3. 下载 JSON 文件
# 4. 将内容转换为 base64 编码
```

#### 环境变量配置
```env
# Firebase 配置
FIREBASE_PROJECT_ID=token-airdrop-signer
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@token-airdrop-signer.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n

# 或使用 base64 编码的服务账号文件
FIREBASE_SERVICE_ACCOUNT_KEY=eyJ0eXBlIjoic2VydmljZV9hY2NvdW50...
```

### 3. Firebase 服务实现

#### `/src/services/firebase.js`
```javascript
const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    this.initializeFirebase();
    this.db = admin.firestore();
  }

  initializeFirebase() {
    if (admin.apps.length === 0) {
      const serviceAccount = this.getServiceAccount();
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID
      });
    }
  }

  getServiceAccount() {
    // 支持多种配置方式
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      // base64 编码的完整服务账号文件
      const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_KEY, 'base64').toString();
      return JSON.parse(decoded);
    } else {
      // 分离的环境变量
      return {
        type: "service_account",
        project_id: process.env.FIREBASE_PROJECT_ID,
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
      };
    }
  }

  async saveUserData(address, data) {
    const userRef = this.db.collection('users').doc(address.toLowerCase());
    await userRef.set({
      ...data,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  }

  async saveSignatureRecord(address, signatureData) {
    const signaturesRef = this.db.collection('signatures');
    await signaturesRef.add({
      userAddress: address.toLowerCase(),
      ...signatureData,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

module.exports = new FirebaseService();
```

### 4. 数据库结构

#### 集合: `users`
```javascript
// 文档 ID: 用户地址（小写）
{
  "address": "0x742d35Cc643C0532e8FCb5d9d5c5F8ce4ac5BB5F",
  "totalClaimed": 1000000000000000000, // wei 单位
  "claimCount": 3,
  "lastClaimedAt": "2025-09-22T10:20:49.136Z",
  "updatedAt": "2025-09-22T10:20:49.136Z"
}
```

#### 集合: `signatures`
```javascript
// 自动生成文档 ID
{
  "userAddress": "0x742d35cc643c0532e8fcb5d9d5c5f8ce4ac5bb5f",
  "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
  "amount": "1000000000000000000",
  "nonce": 12345,
  "signature": "0x1234567890abcdef...",
  "isVerified": true,
  "createdAt": "2025-09-22T10:20:49.136Z"
}
```

## Vercel 部署

### 1. 部署配置

#### `vercel.json`
```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/index.js"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### 2. 环境变量设置

#### Vercel Dashboard 配置
```bash
# 1. 访问 https://vercel.com/dashboard
# 2. 选择项目 → Settings → Environment Variables
# 3. 添加以下变量:

NODE_ENV=production
PRIVATE_KEY=0x1234567890abcdef... # 签名私钥
CONTRACT_ADDRESS=0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569

# Firebase 配置
FIREBASE_PROJECT_ID=token-airdrop-signer
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@token-airdrop-signer.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n

# 或使用 base64 编码
FIREBASE_SERVICE_ACCOUNT_KEY=eyJ0eXBlIjoic2VydmljZV9hY2NvdW50...
```

### 3. 部署流程

#### 自动部署（推荐）
```bash
# 1. 推送代码到 GitHub
git add .
git commit -m "部署更新"
git push origin master

# 2. Vercel 自动检测并部署
# 3. 查看部署状态: https://vercel.com/dashboard
```

#### 手动部署
```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署到生产环境
vercel --prod
```

### 4. 域名和 SSL

#### 自定义域名
```bash
# 1. Vercel Dashboard → Project → Settings → Domains
# 2. 添加自定义域名
# 3. 配置 DNS 记录
# 4. SSL 证书自动配置
```

## 代码架构详解

### 1. 主应用入口 (`src/index.js`)

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// 安全和中间件配置
app.use(helmet()); // 安全头部
app.use(cors({
  origin: '*', // 允许所有来源
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: false
}));
app.use(morgan('combined')); // 请求日志
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 路由配置
app.use('/api/signatures', require('./routes/signatures'));

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'TokenAirDrop Signer Service'
  });
});

// 错误处理
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((error, req, res, next) => {
  console.error('Server Error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
});

const server = app.listen(PORT, () => {
  console.log(`🚀 Signer Service running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`🔥 Firebase Project: ${process.env.FIREBASE_PROJECT_ID}`);
});

module.exports = app;
```

### 2. 签名服务 (`src/services/signer.js`)

```javascript
const { ethers } = require('ethers');

class SignerService {
  constructor() {
    this.privateKey = process.env.PRIVATE_KEY;
    this.contractAddress = process.env.CONTRACT_ADDRESS;
    
    if (!this.privateKey) {
      throw new Error('PRIVATE_KEY environment variable is required');
    }
    
    this.wallet = new ethers.Wallet(this.privateKey);
    
    // EIP-712 域定义
    this.domain = {
      name: "TokenAirDrop",
      version: "1",
      chainId: 11155111, // Sepolia 测试网
      verifyingContract: this.contractAddress
    };
    
    // 签名类型定义
    this.types = {
      ClaimData: [
        { name: "user", type: "address" },
        { name: "token", type: "address" },
        { name: "amount", type: "uint256" },
        { name: "nonce", type: "uint256" }
      ]
    };
  }

  async generateSignature(user, token, amount, nonce) {
    try {
      const value = {
        user: user,
        token: token,
        amount: amount.toString(),
        nonce: nonce
      };

      // 生成 EIP-712 签名
      const signature = await this.wallet.signTypedData(this.domain, this.types, value);
      
      return {
        signature,
        domain: this.domain,
        types: this.types,
        value
      };
    } catch (error) {
      console.error('Signature generation error:', error);
      throw new Error('Failed to generate signature');
    }
  }

  async verifySignature(user, token, amount, nonce, signature) {
    try {
      const value = {
        user: user,
        token: token,
        amount: amount.toString(),
        nonce: nonce
      };

      // 恢复签名者地址
      const recoveredAddress = ethers.verifyTypedData(this.domain, this.types, value, signature);
      
      // 验证签名者是否匹配
      const isValid = recoveredAddress.toLowerCase() === this.wallet.address.toLowerCase();
      
      return {
        isValid,
        recoveredAddress,
        expectedAddress: this.wallet.address
      };
    } catch (error) {
      console.error('Signature verification error:', error);
      return {
        isValid: false,
        error: error.message
      };
    }
  }

  getSignerInfo() {
    return {
      address: this.wallet.address,
      contractAddress: this.contractAddress
    };
  }
}

module.exports = SignerService;
```

### 3. 控制器 (`src/controllers/signatures.js`)

```javascript
const SignerService = require('../services/signer');
const firebaseService = require('../services/firebase');

const signerService = new SignerService();

class SignatureController {
  
  async generateSignature(req, res) {
    try {
      const { user, token, amount, nonce } = req.body;
      
      // 参数验证
      if (!user || !token || !amount || nonce === undefined) {
        return res.status(400).json({
          error: 'Missing required parameters',
          required: ['user', 'token', 'amount', 'nonce']
        });
      }

      // 生成签名
      const signatureData = await signerService.generateSignature(user, token, amount, nonce);
      
      // 保存到 Firebase
      await firebaseService.saveSignatureRecord(user, {
        tokenAddress: token,
        amount: amount.toString(),
        nonce: parseInt(nonce),
        signature: signatureData.signature,
        isVerified: true
      });

      res.json({
        message: 'Signature generated successfully',
        data: signatureData
      });

    } catch (error) {
      console.error('Generate signature error:', error);
      res.status(500).json({
        error: 'Failed to generate signature',
        message: error.message
      });
    }
  }

  async verifySignature(req, res) {
    try {
      const { user, token, amount, nonce, signature } = req.body;
      
      // 参数验证
      if (!user || !token || !amount || nonce === undefined || !signature) {
        return res.status(400).json({
          error: 'Missing required parameters',
          required: ['user', 'token', 'amount', 'nonce', 'signature']
        });
      }

      // 验证签名
      const verificationResult = await signerService.verifySignature(user, token, amount, nonce, signature);
      
      res.json({
        message: 'Signature verification completed',
        data: verificationResult
      });

    } catch (error) {
      console.error('Verify signature error:', error);
      res.status(500).json({
        error: 'Failed to verify signature',
        message: error.message
      });
    }
  }

  async getSignerInfo(req, res) {
    try {
      const signerInfo = signerService.getSignerInfo();
      
      res.json({
        message: 'Signer info retrieved successfully',
        signer: signerInfo
      });

    } catch (error) {
      console.error('Get signer info error:', error);
      res.status(500).json({
        error: 'Failed to get signer info',
        message: error.message
      });
    }
  }
}

module.exports = new SignatureController();
```

## 环境配置

### 1. 本地开发环境

#### `.env` 文件
```env
# 应用配置
NODE_ENV=development
PORT=3000

# 区块链配置
PRIVATE_KEY=0x1234567890abcdef...
CONTRACT_ADDRESS=0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569

# Firebase 配置
FIREBASE_PROJECT_ID=token-airdrop-signer
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@token-airdrop-signer.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
```

### 2. 生产环境

#### Vercel 环境变量
```bash
# 在 Vercel Dashboard 中设置，不要包含在代码中
NODE_ENV=production
PRIVATE_KEY=生产环境私钥
CONTRACT_ADDRESS=生产环境合约地址
FIREBASE_PROJECT_ID=生产环境项目ID
FIREBASE_SERVICE_ACCOUNT_KEY=base64编码的服务账号文件
```

## 开发指南

### 1. 本地开发

#### 安装依赖
```bash
cd signer-node
npm install
```

#### 启动开发服务器
```bash
# 开发模式（带热重载）
npm run dev

# 生产模式
npm start
```

#### 测试 API
```bash
# 健康检查
curl http://localhost:3000/health

# 获取签名者信息
curl http://localhost:3000/api/signatures/signer

# 生成签名
curl -X POST http://localhost:3000/api/signatures/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user": "0x742d35Cc643C0532e8FCb5d9d5c5F8ce4ac5BB5F",
    "token": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000",
    "nonce": 12345
  }'
```

### 2. 调试指南

#### 启用详细日志
```javascript
// 在 src/index.js 中添加
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`, req.body);
    next();
  });
}
```

#### Firebase 调试
```javascript
// 在 firebase.js 中添加
console.log('Firebase initialized:', {
  projectId: admin.app().options.projectId,
  databaseURL: admin.app().options.databaseURL
});
```

### 3. 添加新功能

#### 创建新的控制器
```javascript
// src/controllers/newController.js
class NewController {
  async newMethod(req, res) {
    try {
      // 业务逻辑
      res.json({ message: 'Success' });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = new NewController();
```

#### 添加新路由
```javascript
// src/routes/newRoutes.js
const express = require('express');
const router = express.Router();
const newController = require('../controllers/newController');

router.post('/new-endpoint', newController.newMethod);

module.exports = router;
```

#### 注册路由
```javascript
// 在 src/index.js 中添加
app.use('/api/new', require('./routes/newRoutes'));
```

## 故障排查

### 1. 常见问题

#### Firebase 连接失败
```bash
错误: "Error: Could not load the default credentials"
解决: 检查 FIREBASE_SERVICE_ACCOUNT_KEY 环境变量是否正确设置
```

#### 签名生成失败
```bash
错误: "TypeError: Cannot read property 'signTypedData' of undefined"
解决: 检查 PRIVATE_KEY 环境变量是否正确设置
```

#### Vercel 部署失败
```bash
错误: "The `functions` property cannot be used in conjunction with the `builds` property"
解决: 检查 vercel.json 配置，不要同时使用 builds 和 functions
```

### 2. 日志分析

#### 查看 Vercel 日志
```bash
# 1. Vercel Dashboard → Project → Functions
# 2. 点击具体的函数执行记录
# 3. 查看 "Logs" 标签页
```

#### 本地日志
```javascript
// 在需要调试的地方添加
console.log('Debug info:', { 
  timestamp: new Date().toISOString(),
  data: someData 
});
```

### 3. 性能优化

#### Firebase 连接池
```javascript
// 复用 Firebase 连接
let firebaseApp;
if (!firebaseApp) {
  firebaseApp = admin.initializeApp(config);
}
```

#### 缓存优化
```javascript
// 添加内存缓存
const cache = new Map();

function getCachedData(key) {
  return cache.get(key);
}

function setCachedData(key, data, ttl = 60000) {
  cache.set(key, data);
  setTimeout(() => cache.delete(key), ttl);
}
```

## 总结

这个后端服务提供了完整的 TokenAirDrop 签名功能，包括：

- ✅ **可扩展的架构**: 模块化设计，易于扩展
- ✅ **数据持久化**: Firebase Firestore 集成
- ✅ **云部署**: Vercel 平台自动化部署
- ✅ **安全性**: EIP-712 标准签名，安全头部保护
- ✅ **跨域支持**: 支持前端应用集成
- ✅ **监控和日志**: 完整的请求日志和错误处理

通过这份文档，开发团队可以快速理解和维护整个后端系统。
