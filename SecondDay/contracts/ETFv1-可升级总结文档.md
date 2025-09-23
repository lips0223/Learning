# ETF合约系统部署总结

## 📋 目录
- [合约地址汇总](#合约地址汇总)
- [合约原理与实现](#合约原理与实现)
- [技术架构](#技术架构)
- [Etherscan验证流程](#etherscan验证流程)
- [使用指南](#使用指南)

---

## 🏠 合约地址汇总

### Sepolia 测试网部署地址

| 合约名称 | 地址 | 功能描述 |
|---------|------|----------|
| **ETFv1** | `0x37Ee135db8e41D3F9C15F97918C58651E8A564A6` | 基础ETF合约，支持多代币投资组合 |
| **ETFv2** | `0xe75dDeb4d90F62b0D70CAFe2c8db9B968E29336c` | 增强ETF，支持ETH投资通过Uniswap V3 |
| **ETFv3Lite** | `0xF5cF61a03c562f254501C0693B67B31cAa79Df4C` | 动态再平衡ETF（优化版本） |
| **ETFv4Lite** | `0xa02A55F8c4DA1271C37D13C90A372747295B5a60` | 挖矿奖励ETF（优化版本） |
| **ETFProtocolToken** | `0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499` | 协议治理代币 |
| **ETFUUPSUpgradeable** | `0xEb8f4136578538758eAf2a382E9cB30D897dd958` | 可升级ETF实现合约 |
| **ETFUUPSUpgradeable (Factory)** | `0x30D63b373b0a47447cD9e4c4e10c826C4361F130` | 工厂部署的实现合约 |
| **ETFProxyFactory** | `0x7DD6d4f5507DB3e448FC64d78C37F7A687F27405` | 代理工厂合约 |

---

## 🔧 合约原理与实现

### 1. ETFv1 - 基础ETF合约

**核心原理：**
- 实现多代币投资组合的铸造和赎回
- 用户投入指定代币按比例获得ETF份额
- 赎回时按份额比例返还底层代币

**主要代码实现：**
```solidity
// 核心状态变量
address[] public _tokens;                    // 成分代币数组
uint256[] public _initTokenAmountPerShares; // 每份额对应的代币数量
uint256 public minMintAmount;               // 最小铸造数量

// 核心铸造函数
function mint(uint256[] calldata amounts) external {
    require(amounts.length == _tokens.length, "Length mismatch");
    
    // 计算铸造份额
    uint256 shares = calculateShares(amounts);
    require(shares >= minMintAmount, "Below minimum");
    
    // 转入代币
    for (uint256 i = 0; i < _tokens.length; i++) {
        IERC20(_tokens[i]).transferFrom(msg.sender, address(this), amounts[i]);
    }
    
    // 铸造ETF代币
    _mint(msg.sender, shares);
}
```

### 2. ETFv2 - ETH投资增强版

**核心原理：**
- 继承ETFv1的所有功能
- 新增ETH投资功能，通过Uniswap V3将ETH兑换为成分代币
- 支持WETH包装和解包装

**主要代码实现：**
```solidity
// 继承ETFv1
contract ETFv2 is ETFv1 {
    address public swapRouter;  // Uniswap V3 路由
    address public weth;        // WETH地址
    
    // ETH投资函数
    function investWithETH() external payable {
        require(msg.value > 0, "Invalid ETH amount");
        
        // 包装ETH为WETH
        IWETH(weth).deposit{value: msg.value}();
        
        // 通过Uniswap V3兑换为成分代币
        uint256[] memory amounts = _swapETHToTokens(msg.value);
        
        // 调用基础铸造函数
        _mintWithAmounts(amounts, msg.sender);
    }
}
```

### 3. ETFv3Lite - 动态再平衡ETF

**核心原理：**
- 支持管理员动态调整成分代币权重
- 实现投资组合的自动再平衡
- 简化版本以满足合约大小限制

**主要代码实现：**
```solidity
contract ETFv3Lite is ETFv2 {
    // 动态权重调整
    function rebalance(
        address[] calldata newTokens,
        uint256[] calldata newAmounts
    ) external onlyOwner {
        require(newTokens.length == newAmounts.length, "Length mismatch");
        
        // 更新成分代币配置
        _tokens = newTokens;
        _initTokenAmountPerShares = newAmounts;
        
        emit Rebalanced(newTokens, newAmounts);
    }
}
```

### 4. ETFv4Lite - 挖矿奖励ETF

**核心原理：**
- 继承ETFv2的所有功能
- 新增流动性挖矿奖励机制
- 用户持有ETF可获得协议代币奖励

**主要代码实现：**
```solidity
contract ETFv4Lite is ETFv2 {
    address public protocolToken;     // 奖励代币
    uint256 public rewardRate;        // 奖励率
    
    // 挖矿奖励计算
    function claimRewards(address user) external {
        uint256 userBalance = balanceOf(user);
        uint256 rewards = calculateRewards(user, userBalance);
        
        if (rewards > 0) {
            IERC20(protocolToken).transfer(user, rewards);
            emit RewardsClaimed(user, rewards);
        }
    }
}
```

### 5. ETFProtocolToken - 协议代币

**核心原理：**
- 标准ERC20代币
- 用作协议治理和挖矿奖励
- 固定总供应量

### 6. ETFUUPSUpgradeable - 可升级ETF

**核心原理：**
- 采用UUPS代理升级模式
- 实现合约逻辑的无缝升级
- 保持状态数据不丢失

**主要代码实现：**
```solidity
contract ETFUUPSUpgradeable is 
    Initializable, 
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeableUpgradeable 
{
    // 初始化函数
    function initialize(InitializeParams memory params) public initializer {
        __ERC20_init(params.name, params.symbol);
        __Ownable_init(params.owner);
        __UUPSUpgradeable_init();
        
        // 设置ETF参数
        _tokens = params.tokens;
        _initTokenAmountPerShares = params.initTokenAmountPerShares;
        minMintAmount = params.minMintAmount;
    }
    
    // 升级授权
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyOwner 
    {}
}
```

### 7. ETFProxyFactory - 代理工厂

**核心原理：**
- 批量创建ETF代理合约
- 统一管理实现合约
- 降低单个ETF部署成本

---

## 🏗 技术架构

### 合约继承关系
```
ETFv1 (基础功能)
    ↓
ETFv2 (ETH投资)
    ↓
ETFv3Lite (动态再平衡)

ETFv2
    ↓
ETFv4Lite (挖矿奖励)

ETFUUPSUpgradeable (可升级版本)
    ↑
ETFProxyFactory (工厂模式)
```

### 核心依赖
- **OpenZeppelin**: 安全的智能合约基础库
- **Uniswap V3**: 去中心化交易协议
- **WETH**: 包装以太坊合约

### 优化策略
1. **合约大小优化**: 创建Lite版本以满足24KB限制
2. **Gas优化**: 使用数组批处理和结构体优化
3. **安全性**: 继承OpenZeppelin安全模块

---

## 🔍 Etherscan验证流程

### 方法1: Foundry自动验证
```bash
# 部署时直接验证
forge script script/01_DeployETFv1.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --private-key $PRIVATE_KEY
```

### 方法2: 手动验证扁平化合约

#### 2.1 生成扁平化文件
```bash
# 扁平化合约
forge flatten src/ETFv1/ETFv1.sol > src/ETFv1/flattened/ETFv1_flattened.sol
forge flatten src/ETFv2/ETFv2.sol > src/ETFv2/flattened/ETFv2_flattened.sol
# ... 其他合约类似
```

#### 2.2 Etherscan手动验证步骤

1. **访问Etherscan**
   - 进入 https://sepolia.etherscan.io/
   - 搜索合约地址

2. **选择验证方式**
   - 点击 "Contract" 标签页
   - 点击 "Verify and Publish"
   - 选择 "Single file" 或 "Standard JSON"

3. **填写验证信息**
   ```
   Compiler Type: Solidity (Single file)
   Compiler Version: v0.8.24+commit.e11b9ed9
   License: MIT
   ```

4. **粘贴合约代码**
   - 复制对应的 `*_flattened.sol` 文件内容
   - 粘贴到代码框中

5. **构造函数参数**
   ```
   ETFv1: ["ETF Token","ETF",[token1,token2,token3],[amount1,amount2,amount3],minAmount]
   ETFv2: ["ETF v2","ETFv2",[tokens],[amounts],minAmount,router,weth]
   ```

#### 2.3 验证命令示例
```bash
# 使用forge verify命令
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --compiler-version v0.8.24+commit.e11b9ed9 \
    0x37Ee135db8e41D3F9C15F97918C58651E8A564A6 \
    src/ETFv1/flattened/ETFv1_flattened.sol:ETFv1 \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(string,string,address[],uint256[],uint256)" "ETF Token" "ETF" "[0x779877A7B0D9E8603169DdbD7836e478b4624789,0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844]" "[1000000000000000000,1000000000000000000,1000000000000000000]" "1000000000000000")
```

### 验证状态检查
验证成功后，在Etherscan上可以看到：
- ✅ 绿色对勾标记
- 📖 "Read Contract" 功能
- ✏️ "Write Contract" 功能
- 📄 完整的源代码显示

---

## 📖 使用指南

### 前置条件
1. **环境变量设置**
   ```bash
   export PRIVATE_KEY="your_private_key"
   export SEPOLIA_RPC_URL="your_rpc_url"
   export ETHERSCAN_API_KEY="your_api_key"
   ```

2. **依赖安装**
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```

### 部署流程
```bash
# 1. 编译所有合约
forge build

# 2. 按顺序部署
forge script script/01_DeployETFv1.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/02_DeployETFv2.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/03_DeployETFv3.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/04_DeployETFProtocolToken.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/05_DeployETFv4.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/06_DeployETFUUPSUpgradeable.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
forge script script/07_DeployETFProxyFactory.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

### 合约交互示例
```solidity
// ETFv1 投资
ETFv1 etf = ETFv1(0x37Ee135db8e41D3F9C15F97918C58651E8A564A6);
uint256[] memory amounts = new uint256[](3);
amounts[0] = 1e18; // 1 LINK
amounts[1] = 1e18; // 1 UNI
amounts[2] = 1e18; // 1 ENS
etf.mint(amounts);

// ETFv2 ETH投资
ETFv2 etfv2 = ETFv2(0xe75dDeb4d90F62b0D70CAFe2c8db9B968E29336c);
etfv2.investWithETH{value: 0.1 ether}();
```

---

## 📊 部署统计

- **总合约数量**: 8个
- **部署网络**: Sepolia 测试网
- **编译器版本**: Solidity 0.8.24
- **优化级别**: 200 runs
- **总gas消耗**: ~0.025 ETH
- **验证状态**: 可通过扁平化文件手动验证

---

## 🔗 相关链接

- **Foundry文档**: https://book.getfoundry.sh/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **Uniswap V3**: https://docs.uniswap.org/
- **Etherscan**: https://sepolia.etherscan.io/

---

## 📝 注意事项

1. **合约大小限制**: 以太坊合约大小限制为24KB，部分合约已优化为Lite版本
2. **网络配置**: 确保RPC URL和私钥配置正确
3. **代币地址**: 测试网代币地址可能随时变化，请及时更新
4. **安全提醒**: 私钥和API密钥请妥善保管，不要泄露

---

**部署时间**: 2025年9月23日  
**部署网络**: Sepolia Testnet  
**框架版本**: Foundry + Solidity 0.8.24