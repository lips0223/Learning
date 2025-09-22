# TokenAirDrop 签名服务 API 文档

## 概述
TokenAirDrop 签名服务为用户提供安全的代币空投签名生成功能。该服务使用服务器端私钥为用户的空投请求生成有效签名，确保空投操作的安全性和合法性。

## 生产环境
- **基础 URL**: `https://signer-node-4cqcf0f4x-xiaolis-projects-1babd2b2.vercel.app`
- **健康检查**: `GET /health`
- **API 版本**: v1.0.0

## 认证
当前版本不需要认证，但建议在生产环境中添加适当的认证机制。

---

## API 端点

### 1. 健康检查
检查服务状态和可用性。

**端点**: `GET /health`

**响应示例**:
```json
{
  "status": "OK",
  "timestamp": "2025-09-22T15:19:02.695Z",
  "service": "TokenAirDrop Signer Service"
}
```

---

### 2. 生成签名
为用户的代币空投请求生成签名。

**端点**: `POST /api/signatures/generate`

**请求头**:
```
Content-Type: application/json
```

**请求体**:
```json
{
  "userAddress": "string",     // 用户钱包地址 (必需)
  "tokenAddress": "string",    // 代币合约地址 (必需)
  "amount": "string"           // 空投数量 (wei 格式字符串, 必需)
}
```

**请求示例**:
```json
{
  "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
  "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
  "amount": "1000000000000000000"
}
```

**成功响应** (200):
```json
{
  "message": "Signature generated successfully",
  "data": {
    "signature": "0xb33de1b29c194c3c543f5cea58066757cadd706aa9e9e650b05d137c8fb295bc102caade251fe603577e105ec999b70fdd10236597ab56a3ef1f87b63416fc001b",
    "messageHash": "0x7f95dd5a987f168d7178886255546ad2109a6707bace56c613c3ed25e5eb63c7",
    "signer": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000",
    "nonce": "550333089",
    "id": "mUulRKxUEfEsiV29YsuJ"
  }
}
```

**错误响应** (400):
```json
{
  "error": "Validation failed",
  "details": "userAddress is required"
}
```

**错误响应** (500):
```json
{
  "error": "Failed to generate signature",
  "details": "Internal server error message"
}
```

---

### 3. 环境变量测试 (仅开发调试)
显示当前环境变量配置状态。

**端点**: `GET /api/test-env`

**响应示例**:
```json
{
  "timestamp": "2025-09-22T15:16:43.438Z",
  "env_values": {
    "FIREBASE_PROJECT_ID": "token-airdrop-signer",
    "FIREBASE_CLIENT_EMAIL": "firebase-adminsdk-fbsvc@token-airdrop-signer.iam.gserviceaccount.com",
    "FIREBASE_PRIVATE_KEY": "-----BEGIN PRIVATE KEY-----\n...",
    "SIGNER_PRIVATE_KEY": "0x7ad968ae67253103d1357aefec508469e7e88a4566233b30f100e4498e4ffa4b",
    "TOKEN_AIRDROP_ADDRESS": "0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569",
    "SEPOLIA_RPC_URL": "https://ethereum-sepolia-rpc.publicnode.com",
    "NODE_ENV": "production",
    "VERCEL_ENV": "production"
  }
}
```

---

### 4. Firebase 连接测试 (仅开发调试)
测试 Firebase 服务连接状态。

**端点**: `GET /api/test-firebase`

**响应示例**:
```json
{
  "timestamp": "2025-09-22T15:19:09.137Z",
  "firebase_status": "initialized",
  "config_check": {
    "hasFirebaseProjectId": true,
    "hasFirebasePrivateKey": true,
    "hasFirebaseClientEmail": true,
    "privateKeyLength": 1707
  },
  "result": "Firebase initialized successfully"
}
```

---

## 数据模型

### SignatureData
```typescript
interface SignatureData {
  signature: string;      // 生成的签名 (0x 前缀)
  messageHash: string;    // 消息哈希 (0x 前缀)
  signer: string;         // 签名者地址 (服务器钱包地址)
  userAddress: string;    // 用户钱包地址
  tokenAddress: string;   // 代币合约地址
  amount: string;         // 空投数量 (wei 格式)
  nonce: string;          // 随机数
  id: string;            // Firebase 文档 ID
}
```

---

## 使用示例

### JavaScript/TypeScript
```javascript
// 生成签名
async function generateSignature(userAddress, tokenAddress, amount) {
  const response = await fetch('https://signer-node-4cqcf0f4x-xiaolis-projects-1babd2b2.vercel.app/api/signatures/generate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userAddress,
      tokenAddress,
      amount
    })
  });

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }

  const result = await response.json();
  return result.data;
}

// 使用示例
try {
  const signature = await generateSignature(
    '0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479',
    '0x550a3fc779b68919b378c1925538af7065a2a761',
    '1000000000000000000' // 1 ETH in wei
  );
  console.log('Generated signature:', signature);
} catch (error) {
  console.error('Error generating signature:', error);
}
```

### cURL
```bash
# 生成签名
curl -X POST "https://signer-node-4cqcf0f4x-xiaolis-projects-1babd2b2.vercel.app/api/signatures/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000"
  }'

# 健康检查
curl "https://signer-node-4cqcf0f4x-xiaolis-projects-1babd2b2.vercel.app/health"
```

---

## 错误处理

### 常见错误码
- **400 Bad Request**: 请求参数无效或缺失
- **500 Internal Server Error**: 服务器内部错误

### 错误响应格式
```json
{
  "error": "错误类型",
  "details": "详细错误信息"
}
```

---

## 安全考虑

1. **私钥管理**: 服务器私钥安全存储在环境变量中
2. **签名验证**: 所有生成的签名都保存在 Firebase 中以供审计
3. **输入验证**: 所有输入参数都经过严格验证
4. **HTTPS**: 所有 API 调用都通过 HTTPS 加密传输

---

## 技术栈

- **Runtime**: Node.js
- **Framework**: Express.js
- **部署平台**: Vercel Serverless Functions
- **数据库**: Firebase Firestore
- **区块链库**: ethers.js v6.15.0
- **网络**: Ethereum Sepolia Testnet

---

## 支持

如有问题或需要技术支持，请联系开发团队。

**最后更新**: 2025年9月22日