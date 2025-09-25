# ETFv1 - getInvestTokenAmounts 函数详解

## 📋 函数签名
```solidity
function getInvestTokenAmounts(
    uint256 mintAmount  // 用户想要铸造的 ETF 份额数量
) public view returns (uint256[] memory tokenAmounts) // 返回需要的各成分代币数量
```

## 🎯 函数作用
计算用户投资指定数量的 ETF 份额时，需要投入多少个各种成分代币。

## 💡 核心逻辑分解

### Step 1: 获取当前 ETF 总供应量
```solidity
uint256 totalSupply = totalSupply();  // 当前市面上所有 ETF 份额的总数
tokenAmounts = new uint256[](_tokens.length); // 创建结果数组
```

**作用**：判断这是不是第一次有人投资这个 ETF

### Step 2: 遍历每个成分代币
```solidity
for (uint256 i = 0; i < _tokens.length; i++) {
    // 为每个成分代币计算需要的数量
}
```

### Step 3: 分两种情况计算

#### 情况 1：ETF 已经有人投资过 (totalSupply > 0)
```solidity
if (totalSupply > 0) {
    // 获取合约当前持有的该代币数量
    uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
    
    // 核心公式：按比例计算
    tokenAmounts[i] = tokenReserve.mulDivRoundingUp(
        mintAmount,    // 用户想要的 ETF 份额
        totalSupply    // 当前 ETF 总供应量
    );
}
```

**核心公式推导**：
```
用户需要的代币数量     用户想要的ETF份额
─────────────── = ─────────────
合约持有的代币总量      ETF总供应量

即：tokenAmount / tokenReserve = mintAmount / totalSupply
所以：tokenAmount = tokenReserve × mintAmount / totalSupply
```

#### 情况 2：这是第一次投资 (totalSupply == 0)
```solidity
else {
    // 使用预设的初始比例
    tokenAmounts[i] = mintAmount.mulDivRoundingUp(
        _initTokenAmountPerShares[i],  // 预设的每份ETF对应的代币数量
        1e18  // ETF 的精度 (18位小数)
    );
}
```

**公式**：
```
tokenAmount = mintAmount × initTokenAmountPerShare / 1e18
```

## 🌟 实际例子

假设我们有一个包含 3 种代币的 ETF：
- WETH: 每份 ETF 对应 0.001 个 (1e15)
- LINK: 每份 ETF 对应 1 个 (1e18)  
- UNI: 每份 ETF 对应 1 个 (1e18)

### 例子 1：首次投资
**场景**：
- ETF 总供应量 = 0 (首次投资)
- 用户想要铸造 100 份 ETF (100e18)

**计算过程**：
```solidity
// WETH
tokenAmounts[0] = 100e18 × 1e15 / 1e18 = 0.1 WETH

// LINK  
tokenAmounts[1] = 100e18 × 1e18 / 1e18 = 100 LINK

// UNI
tokenAmounts[2] = 100e18 × 1e18 / 1e18 = 100 UNI
```

**结果**：用户需要投入 0.1 WETH + 100 LINK + 100 UNI

### 例子 2：后续投资
**场景**：
- ETF 总供应量 = 1000 份 (1000e18)
- 合约当前持有：10 WETH, 10000 LINK, 10000 UNI
- 用户想要铸造 100 份 ETF (100e18)

**计算过程**：
```solidity
// WETH
tokenAmounts[0] = 10e18 × 100e18 / 1000e18 = 1 WETH

// LINK
tokenAmounts[1] = 10000e18 × 100e18 / 1000e18 = 1000 LINK  

// UNI
tokenAmounts[2] = 10000e18 × 100e18 / 1000e18 = 1000 UNI
```

**结果**：用户需要投入 1 WETH + 1000 LINK + 1000 UNI

## 🤔 为什么要这样设计？

### 1. 保持比例不变
无论何时投资，都确保 ETF 的成分代币比例保持一致，这样所有投资者的利益是公平的。

### 2. 动态价值反映
当成分代币价格变化时，ETF 的价值也会相应变化，投资者的收益会实时反映市场变化。

### 3. 防止套利
通过严格的比例计算，防止有人通过不公平的价格进行套利。

## 🔍 关键技术点

### 1. mulDivRoundingUp 函数
```solidity
tokenAmounts[i] = tokenReserve.mulDivRoundingUp(mintAmount, totalSupply);
```
- 高精度数学运算，防止溢出
- 向上取整，确保合约有足够的代币储备

### 2. 为什么除以 1e18？
```solidity
tokenAmounts[i] = mintAmount.mulDivRoundingUp(
    _initTokenAmountPerShares[i],
    1e18  // ETF 精度为 18 位
);
```
因为 ETF 代币采用 18 位小数精度，`_initTokenAmountPerShares[i]` 表示每 1 个 ETF (1e18) 对应多少个成分代币。

## 📊 数据流图

```
用户输入: mintAmount (想要的ETF份额)
    ↓
检查 totalSupply 是否为 0
    ↓
┌─────────────────┬─────────────────┐
│   totalSupply > 0    │   totalSupply == 0   │
│   (已有投资者)       │   (首次投资)         │
└─────────────────┴─────────────────┘
    ↓                      ↓
按当前储备比例计算        按初始设定比例计算
    ↓                      ↓
返回各代币需求数量数组
```

## 🎯 总结

这个函数是 ETF 合约的核心，它确保了：

1. **公平性**：所有投资者按相同比例投资
2. **一致性**：ETF 成分始终保持设定的比例
3. **灵活性**：支持首次投资和后续投资
4. **精确性**：使用高精度数学运算避免精度损失

理解了这个函数，你就理解了 ETF 是如何维护成分代币比例，以及用户投资时需要准备哪些代币的核心机制！🎉