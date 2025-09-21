# Foundry ERC20 开发完整教程总结

## 🎉 教程完成情况

### ✅ 已完成的工作

1. **Foundry 环境搭建**
   - ✅ 安装 Foundry 工具链 (v1.3.5-stable)
   - ✅ 初始化项目目录结构
   - ✅ 配置 foundry.toml 文件
   - ✅ 安装 OpenZeppelin 依赖

2. **智能合约开发**
   - ✅ 创建 MockToken.sol (ERC20 代币合约)
   - ✅ 添加自定义 decimals 参数
   - ✅ 实现 mint 函数
   - ✅ 成功编译合约

3. **测试框架**
   - ✅ 创建 MockToken.t.sol 测试文件
   - ✅ 编写 9 个测试用例，覆盖核心功能
   - ✅ 所有测试通过 (9 passed, 0 failed)

4. **部署脚本**
   - ✅ 创建本地部署脚本 (DeployMockToken.s.sol)
   - ✅ 创建测试网部署脚本 (DeploySepoliaMockToken.s.sol)
   - ✅ 创建交互脚本 (InteractMockToken.s.sol)

5. **本地测试**
   - ✅ 启动 Anvil 本地节点
   - ✅ 成功部署到本地网络
   - ✅ 验证合约交互功能

6. **测试网准备**
   - ✅ 配置 Sepolia 网络参数
   - ✅ 创建环境变量模板 (.env.example)
   - ✅ 创建自动化部署脚本 (deploy_sepolia.sh)
   - ✅ 模拟部署成功

### 📋 项目文件结构

```
ERC20/
├── foundry.toml              # Foundry 配置文件
├── .env.example              # 环境变量模板
├── deploy_sepolia.sh         # 自动化部署脚本
├── DEPLOYMENT_GUIDE.md       # 部署指南
├── src/
│   └── MockToken.sol         # ERC20 代币合约
├── test/
│   └── MockToken.t.sol       # 测试文件
├── script/
│   ├── DeployMockToken.s.sol        # 本地部署脚本
│   ├── DeploySepoliaMockToken.s.sol # 测试网部署脚本
│   └── InteractMockToken.s.sol      # 合约交互脚本
├── lib/
│   ├── forge-std/            # Foundry 标准库
│   └── openzeppelin-contracts/ # OpenZeppelin 合约库
└── out/                      # 编译输出目录
```

### 🧪 测试结果摘要

```bash
[PASS] testApprove() (gas: 31126)
[PASS] testBurn() (gas: 53892)
[PASS] testFailMintToZeroAddress() (gas: 13377)
[PASS] testFailTransferFromInsufficientApproval() (gas: 60739)
[PASS] testFailTransferFromInsufficientBalance() (gas: 81516)
[PASS] testFailTransferInsufficientBalance() (gas: 52882)
[PASS] testMint() (gas: 53917)
[PASS] testTransfer() (gas: 60341)
[PASS] testTransferFrom() (gas: 84152)

Test result: ok. 9 passed; 0 failed; 0 skipped; finished in 2.59ms
```

### 🚀 本地部署结果

- **部署地址**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **代币名称**: "Mock Token"
- **代币符号**: "MTK"
- **小数位数**: 18
- **初始铸造**: 1000 MTK (给部署者) + 500 MTK (给用户1)
- **总供应量**: 1500 MTK

### 🔧 主要功能验证

1. **合约部署**: ✅ 成功
2. **代币铸造**: ✅ 成功
3. **余额查询**: ✅ 成功
4. **转账功能**: ✅ 测试通过
5. **授权机制**: ✅ 测试通过
6. **燃烧功能**: ✅ 测试通过

## 🚀 Sepolia 测试网部署 (已完成)

### ✅ 部署成功结果

- **合约地址**: `0xe30e6D1ac45ADfAB41725BE299f1eca041518cd1`
- **代币名称**: "My Test Token" 
- **代币符号**: "MTT"
- **小数位数**: 18
- **初始铸造**: 1,000,000 MTT
- **部署者**: `0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479`
- **Etherscan**: https://sepolia.etherscan.io/address/0xe30e6D1ac45ADfAB41725BE299f1eca041518cd1

## 📝 完整开发命令参考

### 编译命令
```bash
# 清理并重新编译
forge clean && forge build
```

### 测试命令
```bash
# 运行所有测试
forge test -vv
```

### 部署命令
```bash
# 本地部署 (需要先启动 anvil)
forge script script/DeployMockToken.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Sepolia 测试网部署
source .env
forge script script/DeploySepoliaMockToken.s.sol:DeploySepoliaMockToken --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv
```

### 合约交互命令
```bash
# 查询代币信息
cast call 合约地址 "name()" --rpc-url $SEPOLIA_RPC_URL
cast call 合约地址 "symbol()" --rpc-url $SEPOLIA_RPC_URL  
cast call 合约地址 "totalSupply()" --rpc-url $SEPOLIA_RPC_URL

# 查询余额
cast call 合约地址 "balanceOf(address)" 钱包地址 --rpc-url $SEPOLIA_RPC_URL
```

### 合约验证命令
```bash
# 自动验证合约（需要 Etherscan API Key）
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(string,string,uint8)" "My Test Token" "MTT" 18) \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --compiler-version 0.8.30 \
    合约地址 \
    src/MockToken.sol:MockToken

# 生成扁平化文件用于手动验证
forge flatten src/MockToken.sol > MockToken_flattened.sol
```

### 命令参数说明
- `--watch`: 实时监控验证状态，自动重试
- `--chain-id 11155111`: Sepolia 测试网链 ID
- `--num-of-optimizations 200`: 编译优化次数（需与编译时一致）
- `--constructor-args`: 构造函数参数（ABI 编码格式）
- `forge flatten`: 将所有依赖合并到单个文件，用于 Etherscan 手动验证

## 🎯 学习目标达成

通过这个教程，你已经掌握了：

1. **Foundry 基础**: 项目初始化、配置管理、依赖安装
2. **智能合约开发**: ERC20 标准实现、自定义功能添加
3. **测试驱动开发**: 全面的测试用例编写和执行
4. **部署自动化**: 本地和测试网部署脚本编写
5. **合约交互**: 使用 cast 工具与合约交互
6. **最佳实践**: 环境变量管理、安全考虑

