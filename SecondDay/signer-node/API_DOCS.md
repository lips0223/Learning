# TokenAirDrop 签名服务 API 文档

## 基本信息

- **基础 URL**: `https://your-domain.com` (或本地开发: `http://localhost:3000`)
- **版本**: v1.0.0
- **协议**: HTTP/HTTPS
- **数据格式**: JSON

## 认证

当前版本不需要认证，但建议在生产环境中添加 API 密钥或其他认证机制。

## 错误响应格式

所有错误响应都遵循以下格式：

```json
{
  "error": "错误描述",
  "details": "详细错误信息 (可选)"
}
```

## API 端点

### 1. 健康检查

检查服务状态

**URL**: `/health`  
**方法**: `GET`  
**参数**: 无

**成功响应** (200):
```json
{
  "status": "OK",
  "timestamp": "2025-09-22T08:00:00.000Z",
  "service": "TokenAirDrop Signer Service"
}
```

---

### 2. 获取签名者信息

获取签名服务的基本信息

**URL**: `/api/signatures/signer`  
**方法**: `GET`  
**参数**: 无

**成功响应** (200):
```json
{
  "message": "Signer info retrieved successfully",
  "signer": {
    "address": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "contractAddress": "0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569"
  }
}
```

---

### 3. 生成空投签名

为指定用户和代币生成空投签名

**URL**: `/api/signatures/generate`  
**方法**: `POST`  
**Content-Type**: `application/json`

**请求参数**:
```json
{
  "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
  "tokenAddress": "0x1847d3dba09a81e74b31c1d4c9d3220452ab3973",
  "amount": "1000000000000000000"
}
```

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| userAddress | string | ✅ | 接收代币的用户地址 |
| tokenAddress | string | ✅ | 代币合约地址 |
| amount | string | ✅ | 代币数量 (wei 单位) |

**成功响应** (200):
```json
{
  "message": "Signature generated successfully",
  "data": {
    "signature": "0x634bb72cbb77f260c3ecc006ed339b0bc9458571fd9d6cec5dacc784ebe3f0be6e840066c9ee8f776f52672f6e9d8744776847a7c37e49af7d3c8e1556d81a181c",
    "messageHash": "0xb696e944db6047650c7e404a62f15a679ce5fe73b6ed9305a432558468121cc1",
    "signer": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "tokenAddress": "0x1847d3dba09a81e74b31c1d4c9d3220452ab3973",
    "amount": "1000000000000000000",
    "nonce": "503028745",
    "timestamp": 1758528743247,
    "id": "jyXcAGoJ9U6pZ5RxfqRd"
  }
}
```

**错误响应** (400):
```json
{
  "error": "Missing required parameters",
  "required": ["userAddress", "tokenAddress", "amount"]
}
```

---

### 4. 验证签名

验证签名的有效性

**URL**: `/api/signatures/verify`  
**方法**: `POST`  
**Content-Type**: `application/json`

**请求参数**:
```json
{
  "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
  "tokenAddress": "0x1847d3dba09a81e74b31c1d4c9d3220452ab3973",
  "amount": "1000000000000000000",
  "nonce": "503028745",
  "signature": "0x634bb72cbb77f260c3ecc006ed339b0bc9458571fd9d6cec5dacc784ebe3f0be6e840066c9ee8f776f52672f6e9d8744776847a7c37e49af7d3c8e1556d81a181c"
}
```

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| userAddress | string | ✅ | 接收代币的用户地址 |
| tokenAddress | string | ✅ | 代币合约地址 |
| amount | string | ✅ | 代币数量 (wei 单位) |
| nonce | string | ✅ | 随机数 |
| signature | string | ✅ | 待验证的签名 |

**成功响应** (200):
```json
{
  "message": "Signature verification completed",
  "isValid": true,
  "verification": {
    "isValid": true,
    "recoveredAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "expectedAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "messageHash": "0xb696e944db6047650c7e404a62f15a679ce5fe73b6ed9305a432558468121cc1"
  }
}
```

## 使用示例

### JavaScript (fetch)

```javascript
// 生成签名
const generateSignature = async () => {
  const response = await fetch('http://localhost:3000/api/signatures/generate', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      userAddress: '0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479',
      tokenAddress: '0x1847d3dba09a81e74b31c1d4c9d3220452ab3973',
      amount: '1000000000000000000'
    })
  });
  
  const data = await response.json();
  console.log(data);
};

// 验证签名
const verifySignature = async (signatureData) => {
  const response = await fetch('http://localhost:3000/api/signatures/verify', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(signatureData)
  });
  
  const data = await response.json();
  console.log(data);
};
```

### cURL

```bash
# 生成签名
curl -X POST http://localhost:3000/api/signatures/generate \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "tokenAddress": "0x1847d3dba09a81e74b31c1d4c9d3220452ab3973",
    "amount": "1000000000000000000"
  }'

# 验证签名
curl -X POST http://localhost:3000/api/signatures/verify \
  -H "Content-Type: application/json" \
  -d '{
    "userAddress": "0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479",
    "tokenAddress": "0x1847d3dba09a81e74b31c1d4c9d3220452ab3973",
    "amount": "1000000000000000000",
    "nonce": "503028745",
    "signature": "0x634bb72cbb77f260c3ecc006ed339b0bc9458571fd9d6cec5dacc784ebe3f0be6e840066c9ee8f776f52672f6e9d8744776847a7c37e49af7d3c8e1556d81a181c"
  }'
```

## 部署信息

### 合约地址 (Sepolia)

- **TokenAirDrop**: `0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569`
- **签名者地址**: `0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479`

### 代币地址 (Sepolia)

- **Mock WBTC**: `0x550a3fc779b68919b378c1925538af7065a2a761`
- **Mock WETH**: `0x237b68901458be70498b923a943de7f885c89943`
- **Mock LINK**: `0x1847d3dba09a81e74b31c1d4c9d3220452ab3973`
- **Mock USDC**: `0x279b091df8fd4a07a01231dcfea971d2abcae0f8`
- **Mock USDT**: `0xda988ddbbb4797affe6efb1b267b7d4b29b604eb`

## 安全注意事项

1. **生产环境**：在生产环境中使用 HTTPS
2. **签名验证**：始终在客户端验证返回的签名
3. **速率限制**：建议实施 API 速率限制
4. **私钥安全**：确保签名者私钥安全存储
5. **网络安全**：建议使用防火墙和其他安全措施

## 更新日志

### v1.0.0 (2025-09-22)
- 初始版本发布
- 支持签名生成和验证
- 集成 Firebase Firestore
- 健康检查端点
