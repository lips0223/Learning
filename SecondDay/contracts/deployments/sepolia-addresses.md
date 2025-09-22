## Sepolia部署地址记录

### MockTokens 部署信息 (扁平化重新部署版)
部署时间: 2025年9月22日
部署者地址: 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479

**新部署的扁平化合约地址:**
New Mock WBTC: 0x550a3fc779b68919b378c1925538af7065a2a761
New Mock WETH: 0x237b68901458be70498b923a943de7f885c89943  
New Mock LINK: 0x1847d3dba09a81e74b31c1d4c9d3220452ab3973
New Mock USDC: 0x279b091df8fd4a07a01231dcfea971d2abcae0f8
New Mock USDT: 0xda988ddbbb4797affe6efb1b267b7d4b29b604eb

**旧版本地址 (验证困难):**
Mock WBTC: 0x111804f4c285dC5bB4FAc924DA9fD8c721400d15
Mock WETH: 0xb201F40cC23518Ad433930bD4aA6f1262f2a09D5
Mock LINK: 0x54350eE868530B4F5826866b25E140a336f1d940
Mock USDC: 0x58273fEE3F47ed39C5C2c118725071eF5b5CE418
Mock USDT: 0x4692AF93cdA1b91464daD39db41c722B9Dc8F3CF

✅ 新部署的扁平化合约更容易验证，每个合约都有唯一地址

### TokenAirDrop 部署信息
**新部署的扁平化合约地址:**
NEW TokenAirDrop: 0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569
Signer: 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479  
Owner: 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479
交易哈希: 0x983b81f909c0a909e06edcefd1f8d4fc4f75e5adaf155b08623e9bd6d6e69eab

**旧版本地址 (验证困难):**
TokenAirDrop: 0x149b543C30514612449c815e166Ec78f21AF32C2
Signer: 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479  
Owner: 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479
交易哈希: 0xcc69bdcccc48c9c74fb5f866490680d2d7bc9fadb98d6db3a1f62292aa53b728

### Etherscan链接 (新版本扁平化合约)
**新MockTokens需要验证:**
- New Mock WBTC: https://sepolia.etherscan.io/address/0x550a3fc779b68919b378c1925538af7065a2a761
- New Mock WETH: https://sepolia.etherscan.io/address/0x237b68901458be70498b923a943de7f885c89943
- New Mock LINK: https://sepolia.etherscan.io/address/0x1847d3dba09a81e74b31c1d4c9d3220452ab3973
- New Mock USDC: https://sepolia.etherscan.io/address/0x279b091df8fd4a07a01231dcfea971d2abcae0f8
- New Mock USDT: https://sepolia.etherscan.io/address/0xda988ddbbb4797affe6efb1b267b7d4b29b604eb

**NEW TokenAirDrop需要验证:**
- NEW TokenAirDrop: https://sepolia.etherscan.io/address/0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569


### 代币信息
**新部署的扁平化合约:**
- New Mock WBTC (nWBTC): 8 decimals
- New Mock WETH (nWETH): 18 decimals  
- New Mock LINK (nLINK): 18 decimals
- New Mock USDC (nUSDC): 6 decimals
- New Mock USDT (nUSDT): 6 decimals

### 验证配置
**编译器设置:**
- Compiler Version: v0.8.24+commit.e11b9ed9
- Optimization: No (关闭优化)

**源代码文件:**
- MockToken: 使用 flattened/MockToken_flattened_new.sol
- TokenAirDrop: 使用 flattened/TokenAirDrop_flattened_new.sol

### 下一步操作
1. ✅ 新扁平化合约部署完成 (MockTokens + TokenAirDrop)
2. 🔄 验证新合约 (使用扁平化文件，成功率更高)
3. ⚙️ 为所有新MockToken设置NEW TokenAirDrop为minter
4. 🚀 开始前端开发
