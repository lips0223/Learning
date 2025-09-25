# ETFv2 中 Uniswap 交换机制详细解析

## 📋 概述

ETFv2 版本的核心创新在于集成了 Uniswap V3，实现了用户可以用**单一币种**（如 ETH、USDC 等）投资 ETF，系统会自动通过 Uniswap 将这个币种分别兑换成 ETF 所需的**一篮子代币**。

## 🎯 核心原理

### 1. ETF 基本构成
假设我们的 ETF 包含以下成分代币：
- WETH: 每份 ETF 需要 0.001 个
- LINK: 每份 ETF 需要 1 个  
- UNI: 每份 ETF 需要 1 个

用户想要铸造 100 份 ETF，那么需要：
- 0.1 WETH
- 100 LINK
- 100 UNI

### 2. 单币种投资流程

当用户只有 ETH 时，系统如何帮助用户获得这些代币？

## 💡 ETH 投资流程详解

### Step 1: 接收用户的 ETH
```solidity
function investWithETH(
    address to,
    uint256 mintAmount,
    bytes[] memory swapPaths
) external payable {
    // 用户发送 ETH，例如 1 ETH
    uint256 maxETHAmount = msg.value; // 1 ETH
```

### Step 2: 将 ETH 转换为 WETH
```solidity
    // 将 ETH 包装成 WETH（ERC20 代币）
    IWETH(weth).deposit{value: maxETHAmount}();
    _approveToSwapRouter(weth); // 授权给 Uniswap 路由
```

**为什么要转换为 WETH？**
- ETH 是原生代币，不符合 ERC20 标准
- Uniswap V3 只能交换 ERC20 代币
- WETH 是 ETH 的 ERC20 包装版本，1:1 兑换

### Step 3: 计算所需的成分代币数量
```solidity
    address[] memory tokens = getTokens(); // [WETH, LINK, UNI]
    uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);
    // 假设 mintAmount = 100，返回 [0.1 WETH, 100 LINK, 100 UNI]
```

### Step 4: 循环兑换每个成分代币
```solidity
    uint256 totalPaid;
    for (uint256 i = 0; i < tokens.length; i++) {
        if (tokenAmounts[i] == 0) continue;
        
        if (tokens[i] == weth) {
            // 如果成分代币就是 WETH，直接使用，无需兑换
            totalPaid += tokenAmounts[i]; // 增加 0.1 WETH
        } else {
            // 需要兑换：WETH -> LINK 或 WETH -> UNI
            totalPaid += IV3SwapRouter(swapRouter).exactOutput(
                IV3SwapRouter.ExactOutputParams({
                    path: swapPaths[i],           // 兑换路径
                    recipient: address(this),     // 接收地址（ETF合约）
                    deadline: block.timestamp + 300, // 5分钟超时
                    amountOut: tokenAmounts[i],   // 精确输出数量
                    amountInMaximum: type(uint256).max // 最大输入限制
                })
            );
        }
    }
```

### Step 5: 退还多余的 ETH
```solidity
    // 计算剩余的 ETH
    uint256 leftAfterPaid = maxETHAmount - totalPaid;
    
    // 将 WETH 转回 ETH
    IWETH(weth).withdraw(leftAfterPaid);
    
    // 退还给用户
    payable(msg.sender).transfer(leftAfterPaid);
```

### Step 6: 铸造 ETF 代币
```solidity
    // 现在合约已经拥有了所需的所有成分代币，可以铸造 ETF
    _invest(to, mintAmount);
```

## 🔄 Uniswap V3 交换机制

### exactOutput 函数详解

```solidity
IV3SwapRouter(swapRouter).exactOutput(
    IV3SwapRouter.ExactOutputParams({
        path: swapPaths[i],           // 交换路径编码
        recipient: address(this),     // ETF合约地址
        deadline: block.timestamp + 300,
        amountOut: tokenAmounts[i],   // 我们需要得到的精确数量
        amountInMaximum: type(uint256).max
    })
);
```

**关键点：**
- `exactOutput`：精确输出模式，指定我们要得到多少目标代币
- `path`：编码的交换路径，例如 WETH -> 0.3% fee -> LINK
- `amountOut`：精确的输出数量（比如需要 100 LINK）
- `amountInMaximum`：最多愿意支付多少输入代币

### 交换路径（Path）编码

Uniswap V3 使用特殊的路径编码格式：
```
[tokenA][fee][tokenB][fee][tokenC]...
```

例如：WETH -> LINK 的路径可能是：
```
[WETH地址][3000][LINK地址]
```

如果需要多跳：WETH -> USDC -> LINK：
```
[WETH地址][3000][USDC地址][500][LINK地址]
```

## 📊 完整示例

假设用户想用 1 ETH 投资 100 份 ETF：

### 输入：
- 用户发送：1 ETH
- 想要铸造：100 份 ETF
- 交换路径：
  - swapPaths[0]: `0x` (WETH，无需兑换)
  - swapPaths[1]: `WETH地址 + 3000 + LINK地址` (WETH->LINK)
  - swapPaths[2]: `WETH地址 + 3000 + UNI地址` (WETH->UNI)

### 执行过程：
1. **包装ETH**: 1 ETH -> 1 WETH
2. **计算需求**: 
   - 需要 0.1 WETH
   - 需要 100 LINK  
   - 需要 100 UNI
3. **执行兑换**:
   - WETH: 直接使用 0.1 WETH
   - LINK: 用 0.3 WETH 兑换 100 LINK
   - UNI: 用 0.4 WETH 兑换 100 UNI
   - 总消耗: 0.8 WETH
4. **退还余额**: 0.2 WETH -> 0.2 ETH 退还用户
5. **铸造ETF**: 铸造 100 份 ETF 给用户

## 🔧 任意代币投资

ETFv2 还支持用任意 ERC20 代币投资：

```solidity
function investWithToken(
    address srcToken,        // 源代币（如 USDC）
    address to,
    uint256 mintAmount,
    uint256 maxSrcTokenAmount,
    bytes[] memory swapPaths  // 从 USDC 到各成分代币的路径
) external
```

**流程类似**：
1. 用户授权并转入源代币（如 USDC）
2. 通过 Uniswap 将 USDC 分别兑换成 WETH, LINK, UNI
3. 铸造 ETF 代币
4. 退还多余的源代币

## 🎭 赎回机制

赎回是投资的逆向过程：

```solidity
function redeemToETH(
    address to,
    uint256 burnAmount,      // 要销毁的 ETF 数量
    uint256 minETHAmount,    // 最少收到的 ETH（滑点保护）
    bytes[] memory swapPaths // 从各成分代币到 WETH 的路径
) external
```

**赎回流程**：
1. 销毁用户的 ETF 代币
2. 按比例释放成分代币到合约
3. 将所有成分代币通过 Uniswap 兑换成 WETH
4. 将 WETH 转换成 ETH 发送给用户

## 🛡️ 安全机制

### 1. 路径验证
```solidity
function _checkSwapPath(
    address tokenA,
    address tokenB,
    bytes memory path
) internal pure returns (bool)
```

确保交换路径的起始和结束代币正确。

### 2. 滑点保护
- 投资时设置 `amountInMaximum`
- 赎回时设置 `minETHAmount`

### 3. 时间限制
- 每次交换设置 `deadline`，防止交易被延迟执行

### 4. 授权管理
- 只在需要时授权给 Uniswap 路由
- 使用 `forceApprove` 避免授权问题

## 🚀 优势总结

1. **用户友好**：用户只需持有一种代币就能投资多元化的 ETF
2. **自动化**：系统自动处理复杂的多币种兑换
3. **灵活性**：支持任意 ERC20 代币投资
4. **透明性**：所有兑换都在链上执行，完全透明
5. **高效性**：利用 Uniswap V3 的集中流动性获得更好的兑换率

## 🎯 关键代码片段

### 核心兑换逻辑
```solidity
// 精确输出模式：我们需要特定数量的目标代币
totalPaid += IV3SwapRouter(swapRouter).exactOutput(
    IV3SwapRouter.ExactOutputParams({
        path: swapPaths[i],
        recipient: address(this),
        deadline: block.timestamp + 300,
        amountOut: tokenAmounts[i],      // 需要的精确数量
        amountInMaximum: type(uint256).max
    })
);
```

这就是 ETFv2 实现"一币投万币"的核心机制！🎉