# TokenAirDrop Signer Service API 文档

## 基本信息

- **Base URL**: `https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app`
- **协议**: HTTPS
- **数据格式**: JSON
- **跨域支持**: ✅ 支持所有来源 (`Access-Control-Allow-Origin: *`)

## 认证

当前版本无需认证，所有接口均为公开访问。

## 接口列表

### 1. 健康检查

检查服务运行状态。

**请求**
```
GET /health
```

**响应示例**
```json
{
  "status": "OK",
  "timestamp": "2025-09-22T10:20:49.136Z",
  "service": "TokenAirDrop Signer Service"
}
```

**状态码**
- `200` - 服务正常运行

---

### 2. 获取签名者信息

获取当前签名者的地址和合约地址信息。

**请求**
```
GET /api/signatures/signer
```

**响应示例**
```json
{
  "message": "Signer info retrieved successfully",
  "signer": {
    "address": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "contractAddress": "0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569"
  }
}
```

**字段说明**
- `address`: 签名者钱包地址
- `contractAddress`: TokenAirDrop 合约地址

**状态码**
- `200` - 成功获取信息

---

### 3. 生成签名

为指定用户生成 TokenAirDrop 签名。

**请求**
```
POST /api/signatures/generate
Content-Type: application/json
```

**请求体**
```json
{
  "userAddress": "0x1234567890123456789012345678901234567890",
  "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
  "amount": "1000000000000000000",
  "nonce": 1
}
```

**字段说明**
- `userAddress` (string, 必需): 接收空投的用户地址
- `tokenAddress` (string, 必需): 代币合约地址
- `amount` (string, 必需): 空投数量 (wei 单位)
- `nonce` (number, 必需): 防重放攻击的随机数

**响应示例**
```json
{
  "message": "Signature generated successfully",
  "signature": "0x1234567890abcdef...",
  "data": {
    "userAddress": "0x1234567890123456789012345678901234567890",
    "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000",
    "nonce": 1,
    "timestamp": "2025-09-22T10:25:30.123Z"
  },
  "firebaseId": "doc_12345"
}
```

**字段说明**
- `signature`: 生成的签名字符串
- `data`: 签名的原始数据
- `firebaseId`: Firebase 数据库中的记录 ID

**状态码**
- `200` - 签名生成成功
- `400` - 请求参数错误
- `500` - 服务器内部错误

**错误响应示例**
```json
{
  "error": "Missing required field: userAddress"
}
```

---

### 4. 验证签名

验证给定签名的有效性。

**请求**
```
POST /api/signatures/verify
Content-Type: application/json
```

**请求体**
```json
{
  "userAddress": "0x1234567890123456789012345678901234567890",
  "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
  "amount": "1000000000000000000",
  "nonce": 1,
  "signature": "0x1234567890abcdef..."
}
```

**字段说明**
- `userAddress` (string, 必需): 用户地址
- `tokenAddress` (string, 必需): 代币合约地址
- `amount` (string, 必需): 空投数量
- `nonce` (number, 必需): 随机数
- `signature` (string, 必需): 要验证的签名

**响应示例 - 验证成功**
```json
{
  "message": "Signature verification successful",
  "isValid": true,
  "recoveredSigner": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479"
}
```

**响应示例 - 验证失败**
```json
{
  "message": "Signature verification failed",
  "isValid": false,
  "error": "Invalid signature"
}
```

**字段说明**
- `isValid`: 签名是否有效
- `recoveredSigner`: 从签名中恢复的签名者地址
- `error`: 验证失败时的错误信息

**状态码**
- `200` - 验证完成 (无论成功失败)
- `400` - 请求参数错误
- `500` - 服务器内部错误

---

## 跨域支持 (CORS)

本 API 支持跨域请求，配置如下：

- **Allow-Origin**: `*` (允许所有来源)
- **Allow-Methods**: `GET, POST, PUT, DELETE, OPTIONS`
- **Allow-Headers**: `Content-Type, Authorization, X-Requested-With`

### 预检请求示例

```bash
curl -X OPTIONS \
  -H "Origin: https://your-frontend.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app/api/signatures/generate
```

---

## 使用示例

### JavaScript/TypeScript

```javascript
const API_BASE = 'https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app';

// 获取签名者信息
async function getSignerInfo() {
  const response = await fetch(`${API_BASE}/api/signatures/signer`);
  const data = await response.json();
  return data;
}

// 生成签名
async function generateSignature(userAddress, tokenAddress, amount, nonce) {
  const response = await fetch(`${API_BASE}/api/signatures/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userAddress,
      tokenAddress,
      amount,
      nonce
    })
  });
  const data = await response.json();
  return data;
}

// 验证签名
async function verifySignature(userAddress, tokenAddress, amount, nonce, signature) {
  const response = await fetch(`${API_BASE}/api/signatures/verify`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userAddress,
      tokenAddress,
      amount,
      nonce,
      signature
    })
  });
  const data = await response.json();
  return data;
}
```

### cURL 示例

```bash
# 健康检查
curl https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app/health

# 获取签名者信息
curl https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app/api/signatures/signer

# 生成签名
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0x1234567890123456789012345678901234567890",
    "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000",
    "nonce": 1
  }' \
  https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app/api/signatures/generate

# 验证签名
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0x1234567890123456789012345678901234567890",
    "tokenAddress": "0x550a3fc779b68919b378c1925538af7065a2a761",
    "amount": "1000000000000000000",
    "nonce": 1,
    "signature": "0x1234567890abcdef..."
  }' \
  https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app/api/signatures/verify
```

---

## 合约集成

此 API 配合以下智能合约使用：

- **TokenAirDrop 合约**: `0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569`
- **支持的代币合约**:
  - WBTC: `0x550a3fc779b68919b378c1925538af7065a2a761`
  - USDT: `0x2fc07d44c9b6c829ac0db8c3bb9b3a1d1ca50bbc`
  - DAI: `0xf1f5bff1bf51b01e26b1f0b8e3b0b6e71b9cb17e`
  - USDC: `0x1bc8a90c70ad94fb51d69a5b50b2b4c01c6c16de`
  - WETH: `0x3e7e7b1e7b1e7b1e7b1e7b1e7b1e7b1e7b1e7b1e`

---

## 错误码说明

- `200` - 请求成功
- `400` - 请求参数错误
- `404` - 接口不存在
- `500` - 服务器内部错误

---

## 技术栈

- **运行环境**: Node.js
- **框架**: Express.js
- **区块链库**: Ethers.js v6.15.0
- **数据库**: Firebase Firestore
- **部署平台**: Vercel
- **跨域支持**: CORS 中间件

---

## 更新日志

### v1.0.0 (2025-09-22)
- ✅ 初始版本发布
- ✅ 支持签名生成和验证
- ✅ Firebase 数据存储
- ✅ 完整的跨域支持
- ✅ Vercel 云端部署

---

## 联系支持

如有问题或建议，请通过以下方式联系：
- GitHub: [Learning Repository](https://github.com/lips0223/Learning)
- 项目路径: `SecondDay/signer-node`
