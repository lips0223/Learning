# ETFv3 详细解读：动态再平衡ETF合约

## 🎯 ETFv3 vs ETFv2 核心差异

ETFv3 在 ETFv2 基础上增加了**智能化管理**功能，从静态ETF升级为**动态再平衡ETF**。

### 📋 版本对比表

| 功能特性 | ETFv1 | ETFv2 | ETFv3 |
|----------|-------|--------|--------|
| 基础投资/赎回 | ✅ | ✅ | ✅ |
| 任意代币投资 | ❌ | ✅ | ✅ |
| Uniswap集成 | ❌ | ✅ | ✅ |
| **动态代币管理** | ❌ | ❌ | ✅ |
| **自动再平衡** | ❌ | ❌ | ✅ |
| **价格预言机** | ❌ | ❌ | ✅ |
| **权重管理** | ❌ | ❌ | ✅ |

## 🚀 ETFv3 新增核心功能

### 1. 动态代币管理

#### 添加代币
```solidity
function addToken(address token) external onlyOwner {
    _addToken(token);  // 继承自ETFv1的内部函数
}
```

#### 移除代币
```solidity
function removeToken(address token) external onlyOwner {
    // 安全检查：只能移除余额为0且权重为0的代币
    if (
        IERC20(token).balanceOf(address(this)) > 0 ||
        getTokenTargetWeight[token] > 0
    ) revert Forbidden();
    _removeToken(token);
}
```

### 2. 价格预言机集成（Chainlink）

#### 价格预言机映射
```solidity
/// @dev 代币地址 => Chainlink价格预言机地址
mapping(address token => address priceFeed) public getPriceFeed;
```

#### 设置价格预言机
```solidity
function setPriceFeeds(
    address[] memory tokens,
    address[] memory priceFeeds
) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
        getPriceFeed[tokens[i]] = priceFeeds[i];
    }
}
```

#### 获取实时价格
```solidity
// 在getTokenMarketValues函数中
AggregatorV3Interface priceFeed = AggregatorV3Interface(getPriceFeed[tokens[i]]);
(, tokenPrices[i], , , ) = priceFeed.latestRoundData();  // 获取最新价格
```

### 3. 权重管理系统

#### 目标权重映射
```solidity
/// @dev 代币地址 => 目标权重（基点，10000=100%）
mapping(address token => uint24 targetWeight) public getTokenTargetWeight;
```

#### 设置目标权重
```solidity
function setTokenTargetWeights(
    address[] memory tokens,
    uint24[] memory targetWeights
) external onlyOwner {
    for (uint256 i = 0; i < targetWeights.length; i++) {
        getTokenTargetWeight[tokens[i]] = targetWeights[i];
    }
}
```

### 4. 自动再平衡系统

这是 ETFv3 的**核心创新功能**！

#### 再平衡参数
```solidity
uint256 public lastRebalanceTime;      // 上次再平衡时间
uint256 public rebalanceInterval;      // 再平衡间隔（如24小时）
uint24 public rebalanceDeviance;       // 偏差阈值（如500基点=5%）
```

## 🔧 再平衡机制详解

### 核心原理

再平衡的目标是**保持各代币的实际权重接近目标权重**。

#### Step 1: 计算当前市值分布
```solidity
function getTokenMarketValues() returns (
    address[] memory tokens,
    int256[] memory tokenPrices,      // Chainlink实时价格
    uint256[] memory tokenMarketValues, // 各代币市值
    uint256 totalValues               // 总市值
)
```

**计算逻辑**：
```solidity
// 市值 = 持仓量 × 实时价格
tokenMarketValues[i] = reserve.mulDiv(
    uint256(tokenPrices[i]),
    10 ** tokenDecimals
);
```

#### Step 2: 检查是否需要再平衡
```solidity
// 计算目标市值
uint256 weightedValue = (totalValues * getTokenTargetWeight[tokens[i]]) / HUNDRED_PERCENT;

// 计算允许的偏差范围
uint256 lowerValue = (weightedValue * (HUNDRED_PERCENT - rebalanceDeviance)) / HUNDRED_PERCENT;
uint256 upperValue = (weightedValue * (HUNDRED_PERCENT + rebalanceDeviance)) / HUNDRED_PERCENT;

// 判断是否超出允许范围
if (tokenMarketValues[i] < lowerValue || tokenMarketValues[i] > upperValue) {
    // 需要再平衡！
}
```

#### Step 3: 计算需要调整的数量
```solidity
int256 deltaValue = int256(weightedValue) - int256(tokenMarketValues[i]);

if (deltaValue > 0) {
    // 需要买入更多该代币
    tokenSwapableAmounts[i] = deltaValue / tokenPrice;
} else {
    // 需要卖出部分该代币
    tokenSwapableAmounts[i] = -(-deltaValue) / tokenPrice;
}
```

#### Step 4: 执行代币交换
```solidity
function _swapTokens(
    address[] memory tokens,
    int256[] memory tokenSwapableAmounts
) internal {
    // 第一步：卖出过多的代币，换成USDC
    uint256 usdcRemaining = _sellTokens(usdc, tokens, tokenSwapableAmounts);
    
    // 第二步：用USDC买入不足的代币
    usdcRemaining = _buyTokens(usdc, tokens, tokenSwapableAmounts, usdcRemaining);
    
    // 第三步：剩余USDC按权重分配买入
    if (usdcRemaining > 0) {
        // 按目标权重比例分配剩余USDC
    }
}
```

## 🎨 再平衡实例演示

### 场景设置
- **ETF配置**：WETH(40%) + LINK(30%) + UNI(30%)
- **当前状态**：
  - WETH: 10个，价格$3000，市值$30000 (60%) 📈 **超配**
  - LINK: 100个，价格$15，市值$1500 (3%) 📉 **低配**  
  - UNI: 500个，价格$7，市值$3500 (7%) 📉 **低配**
  - **总市值**: $35000

### 目标权重计算
- WETH目标市值：$35000 × 40% = $14000
- LINK目标市值：$35000 × 30% = $10500  
- UNI目标市值：$35000 × 30% = $10500

### 需要调整的金额
- WETH：$30000 - $14000 = **-$16000** (需要卖出)
- LINK：$1500 - $10500 = **+$9000** (需要买入)
- UNI：$3500 - $10500 = **+$7000** (需要买入)

### 执行步骤

#### Step 1: 卖出WETH
```solidity
// 卖出5.33个WETH (约$16000)
_sellTokens(...) 
// 获得16000 USDC
```

#### Step 2: 买入LINK和UNI
```solidity
// 用9000 USDC买入600个LINK
// 用7000 USDC买入1000个UNI
_buyTokens(...)
```

#### Step 3: 再平衡完成
- WETH: 4.67个，市值$14000 (40%) ✅
- LINK: 700个，市值$10500 (30%) ✅
- UNI: 1500个，市值$10500 (30%) ✅

## 🛡️ 安全机制

### 1. 时间间隔控制
```solidity
if (block.timestamp < lastRebalanceTime + rebalanceInterval)
    revert NotRebalanceTime();
```
防止频繁再平衡导致的Gas浪费和MEV攻击。

### 2. 权重验证
```solidity
modifier _checkTotalWeights() {
    uint24 totalWeights;
    for (uint256 i = 0; i < tokens.length; i++) {
        totalWeights += getTokenTargetWeight[tokens[i]];
    }
    if (totalWeights != HUNDRED_PERCENT) revert InvalidTotalWeights();
    _;
}
```
确保所有代币权重总和等于100%。

### 3. 偏差阈值
```solidity
uint24 public rebalanceDeviance;  // 如500基点 = 5%
```
只有权重偏差超过阈值才触发再平衡，避免因小幅波动频繁调整。

### 4. 移除代币安全检查  
```solidity
if (
    IERC20(token).balanceOf(address(this)) > 0 ||
    getTokenTargetWeight[token] > 0
) revert Forbidden();
```
只能移除余额为0且权重为0的代币。

## 🔗 ETFQuoter 集成

ETFv3 集成了专门的报价合约来优化交换路径：

```solidity
address public etfQuoter;

// 获取最优交换路径和价格
(bytes memory path, uint256 amountIn) = IETFQuoter(etfQuoter).quoteExactOut(
    usdc,
    tokens[i], 
    uint256(tokenSwapableAmounts[i])
);
```

这提供了比用户手动指定路径更优的价格。

## 🎯 ETFv3 优势总结

### 1. **智能化管理**
- 自动根据市场价格调整持仓比例
- Chainlink预言机提供准确价格数据

### 2. **灵活性**
- 动态添加/移除成分代币
- 可调整各代币目标权重

### 3. **资本效率**
- 保持目标权重，优化收益风险比
- 自动止盈止损，减少人为情绪影响

### 4. **专业化**
- 集成专业报价服务
- 多重安全检查机制

### 5. **可定制性**
- 可配置再平衡间隔和偏差阈值
- 支持不同投资策略的权重配置

## 🔄 使用流程

### 管理员设置
1. 部署ETFv3合约
2. 设置价格预言机：`setPriceFeeds()`  
3. 配置目标权重：`setTokenTargetWeights()`
4. 设置再平衡参数：`updateRebalanceInterval()`, `updateRebalanceDeviance()`

### 自动运行
1. 价格监控：持续获取Chainlink价格数据
2. 偏差检测：计算实际权重vs目标权重
3. 触发再平衡：当偏差超过阈值且时间间隔满足时
4. 执行交换：自动卖出超配资产，买入低配资产

### 用户体验
- 用户正常投资赎回，无需关心再平衡细节
- 享受专业化的资产配置和风险管理
- 获得更稳定的长期收益

ETFv3 将传统ETF的专业管理能力带到了DeFi世界，实现了真正的**智能化资产管理**！🚀