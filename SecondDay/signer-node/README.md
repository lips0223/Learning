# Signer Node Service

基于 Node.js + Firebase 的 TokenAirDrop 签名服务

## 功能特性

- 🔐 用户注册和身份验证
- ✍️ 空投签名生成
- 🔍 签名验证
- 💾 Firebase Firestore 数据存储
- 🚀 RESTful API 接口

## 技术栈

- **后端**: Node.js + Express
- **数据库**: Firebase Firestore
- **区块链**: Ethers.js
- **部署**: Firebase Functions (可选)

## API 接口

### 用户管理
- `POST /api/users/register` - 用户注册
- `GET /api/users/:address` - 获取用户信息

### 签名服务
- `POST /api/signatures/generate` - 生成空投签名
- `POST /api/signatures/verify` - 验证签名
- `GET /api/signatures/:address` - 获取用户签名历史

## 安装和运行

```bash
# 安装依赖
npm install

# 配置环境变量
cp .env.example .env

# 启动开发服务器
npm run dev

# 启动生产服务器
npm start
```

## 环境配置

需要配置以下环境变量：
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`
- `SIGNER_PRIVATE_KEY`
- `PORT`
