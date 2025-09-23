# ETF合约系列完整文档

## 📚 目录
1. [项目概览](#项目概览)
2. [ETFv1 - 基础ETF合约](#etfv1---基础etf合约)
3. [ETFv2 - 增强版ETF合约](#etfv2---增强版etf合约)
4. [ETFv3Lite - 时间锁定版ETF](#etfv3lite---时间锁定版etf)
5. [ETFv4Lite - 价格预言机版ETF](#etfv4lite---价格预言机版etf)
6. [可升级合约系列](#可升级合约系列)
7. [部署地址](#部署地址)
8. [使用指南](#使用指南)

---

## 🎯 项目概览

### 什么是ETF合约？

ETF（Exchange Traded Fund）合约是一个去中心化的投资基金合约，它将多种加密货币代币组合成一个投资组合，用户可以通过购买ETF代币来间接持有这些底层资产。

### 技术架构

```
ETFv1 (基础版)
├── 基本投资和赎回功能
├── 多代币组合管理
└── ERC20标准兼容

ETFv2 (增强版)
├── 继承ETFv1所有功能
├── ETH直接投资
├── Uniswap V3集成
└── 任意代币交换

ETFv3Lite (时间锁定版)
├── 继承ETFv2所有功能
├── 时间锁定机制
├── 锁定投资激励
└── 风险管理

ETFv4Lite (价格预言机版)
├── 继承ETFv3Lite所有功能
├── Uniswap价格预言机
├── 实时价格监控
├── 价格保护机制
└── 紧急暂停功能
```

---

## 🚀 ETFv1 - 基础ETF合约

### 核心功能

#### 1. 基本投资功能
```solidity
function invest(uint256 mintAmount) external
```
- **功能**: 用户提供成分代币，获得ETF份额
- **参数**: `mintAmount` - 要铸造的ETF数量
- **前置条件**: 用户需要拥有足够的成分代币并授权合约

#### 2. 赎回功能
```solidity
function redeem(uint256 burnAmount) external
```
- **功能**: 用户燃烧ETF份额，获得成分代币
- **参数**: `burnAmount` - 要燃烧的ETF数量
- **前置条件**: 用户需要拥有足够的ETF份额

#### 3. 查询函数
```solidity
function getTokens() external view returns (address[] memory)
function getInitTokenAmountPerShares() external view returns (uint256[] memory)
function getInvestTokenAmounts(uint256 mintAmount) external view returns (uint256[] memory)
function getRedeemTokenAmounts(uint256 burnAmount) external view returns (uint256[] memory)
```

### 成分代币配置

**当前配置**:
- WETH: `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9`
- LINK: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- UNI: `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984`

**权重比例**:
- WETH: 0.001 ETH (1,000,000,000,000,000 wei)
- LINK: 1 LINK (1,000,000,000,000,000,000 wei)
- UNI: 1 UNI (1,000,000,000,000,000,000 wei)

### 使用流程

1. **投资流程**:
   ```
   用户 → 授权代币 → 调用invest() → 获得ETF份额
   ```

2. **赎回流程**:
   ```
   用户 → 调用redeem() → 燃烧ETF份额 → 获得成分代币
   ```

---

## ⚡ ETFv2 - 增强版ETF合约

### 新增功能

#### 1. ETH直接投资
```solidity
function investWithETH(bytes[] calldata swapPaths, uint256 deadline) external payable returns (uint256 shares)
```
- **功能**: 用户直接用ETH投资，自动通过Uniswap交换为成分代币
- **参数**: 
  - `swapPaths` - Uniswap交换路径
  - `deadline` - 交易截止时间
- **返回**: 获得的ETF份额数量

#### 2. ETH赎回
```solidity
function redeemWithETH(uint256 burnAmount, bytes[] calldata swapPaths, uint256 deadline) external returns (uint256 ethAmount)
```
- **功能**: 赎回ETF份额，自动将成分代币交换为ETH
- **参数**:
  - `burnAmount` - 要燃烧的ETF数量
  - `swapPaths` - Uniswap交换路径
  - `deadline` - 交易截止时间

#### 3. 任意代币投资
```solidity
function investWithToken(address investToken, uint256 investAmount, bytes[] calldata swapPaths, uint256 deadline) external returns (uint256 shares)
```
- **功能**: 用任意ERC20代币投资ETF
- **使用场景**: 用户只有USDC，想投资包含WETH/LINK/UNI的ETF

#### 4. 任意代币赎回
```solidity
function redeemWithToken(uint256 burnAmount, address targetToken, bytes[] calldata swapPaths, uint256 deadline) external returns (uint256 tokenAmount)
```
- **功能**: 赎回ETF并换成指定代币

### 技术亮点

- **Uniswap V3集成**: 利用最新的DEX技术实现高效交换
- **路径优化**: 支持多跳交换，降低滑点
- **Gas优化**: 批量操作减少交易费用

---

## 🔒 ETFv3Lite - 时间锁定版ETF

### 时间锁定机制

#### 1. 锁定投资
```solidity
function investWithLock(uint256 mintAmount) external
```
- **功能**: 投资并锁定资产一段时间
- **锁定期**: 86,400秒（24小时）
- **限制**: 锁定期间无法赎回

#### 2. ETH锁定投资
```solidity
function investWithETHAndLock(bytes[] calldata swapPaths, uint256 deadline) external payable returns (uint256 shares)
```
- **功能**: 用ETH投资并锁定

#### 3. 锁定状态查询
```solidity
function lockEndTime(address account) external view returns (uint256)
function canRedeem(address account) external view returns (bool)
```

### 风险管理机制

1. **时间锁定**: 防止短期投机，鼓励长期持有
2. **锁定查询**: 用户可随时查看解锁时间
3. **分层投资**: 支持普通投资和锁定投资并存

### 激励机制

- 锁定投资者可能获得额外收益分配
- 降低ETF的整体波动性
- 提升长期投资者权益

---

## 📊 ETFv4Lite - 价格预言机版ETF

### 价格预言机功能

#### 1. 实时价格查询
```solidity
function getTokenPrice(address token) external view returns (uint256 price)
function getTotalValue() external view returns (uint256 totalValue)
function getSharePrice() external view returns (uint256 price)
```

#### 2. 价格保护投资
```solidity
function investWithPriceCheck(uint256 mintAmount, uint256 maxPricePerShare) external
function redeemWithPriceCheck(uint256 burnAmount, uint256 minPricePerShare) external
```
- **功能**: 带价格保护的投资和赎回
- **保护机制**: 价格超出预期范围时交易失败

#### 3. 紧急控制
```solidity
function emergencyPause() external
function emergencyUnpause() external
function paused() external view returns (bool)
```

### 成分代币 (简化版)

**ETFv4Lite配置**:
- LINK: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- UNI: `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984`

**权重**:
- LINK: 10 LINK
- UNI: 5 UNI

### 安全特性

1. **价格监控**: 实时监控成分代币价格变化
2. **异常检测**: 价格剧烈波动时自动保护
3. **紧急暂停**: 管理员可在紧急情况下暂停合约
4. **MEV保护**: 通过价格检查防止MEV攻击

---

## 🔄 可升级合约系列

### ETFProtocolToken
- **类型**: 治理代币
- **功能**: 协议治理和激励分发
- **地址**: `0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499`

### ETFUUPSUpgradeable
- **类型**: UUPS可升级代理合约
- **功能**: 支持合约逻辑升级而不改变地址
- **特点**: 
  - 实现UUPS升级模式
  - 保持状态不变
  - 向后兼容

### ETFProxyFactory
- **类型**: 代理工厂合约
- **功能**: 批量部署ETF代理合约
- **用途**: 
  - 降低部署成本
  - 标准化ETF创建流程
  - 支持最小代理模式

---

## 📍 部署地址

### Sepolia测试网

| 合约名称 | 地址 | 验证状态 |
|---------|------|----------|
| ETFv1 | `0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E` | ✅ 已验证 |
| ETFv2 | `0xd9c9b65da9be4e7c8b657fa0d71e49f8dc789a6e` | ✅ 已验证 |
| ETFv3Lite | `0xab08bc34c0512b9c6ff41fc7cd7bb6e8bfa6a9b3` | ✅ 已验证 |
| ETFv4Lite | `0x1232da7fce1beb93b9b72b3be2c8a93b8b2bf65b` | ✅ 已验证 |
| ETFProtocolToken | `0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499` | ✅ 已验证 |
| ETFUUPSUpgradeable | `0xAedf21a29F0c22E3db20C77B0bE3E4c3e9E80B0F` | ✅ 已验证 |
| ETFProxyFactory | `0xe51b4a5E8F7B4E12C3B1C0F2E4f5e1dcA7C8C9B5` | ✅ 已验证 |

### 测试代币地址

| 代币名称 | 地址 | 说明 |
|---------|------|------|
| WETH | `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9` | Sepolia官方WETH |
| LINK | `0x779877A7B0D9E8603169DdbD7836e478b4624789` | Sepolia官方LINK |
| UNI | `0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984` | Sepolia官方UNI |

---

## 📖 使用指南

### 前端集成

1. **连接钱包**: 使用RainbowKit连接MetaMask等钱包
2. **选择ETF版本**: 根据需求选择ETFv1-v4或可升级版本
3. **投资操作**: 
   - 授权代币使用权限
   - 选择投资金额
   - 确认交易
4. **赎回操作**: 直接赎回或选择特定代币赎回

### 开发者集成

```javascript
// 1. 安装依赖
npm install wagmi viem @rainbow-me/rainbowkit

// 2. 配置合约
import { CONTRACT_ADDRESSES } from './lib/contracts';
import { ETFv1_ABI } from './lib/abis';

// 3. 使用Wagmi hooks
const { data: balance } = useReadContract({
  address: CONTRACT_ADDRESSES.ETFv1,
  abi: ETFv1_ABI,
  functionName: 'balanceOf',
  args: [userAddress],
});
```

### 安全注意事项

1. **代币授权**: 仅授权必要数量，避免无限授权
2. **价格滑点**: 设置合理的滑点保护
3. **锁定期**: 了解锁定机制，避免流动性风险
4. **测试网使用**: 当前为测试版本，仅用于学习和测试

---

## 🛠 技术特性

### 智能合约特性

- **模块化设计**: 每个版本都是前一版本的增强
- **向前兼容**: 新版本保持对旧接口的支持
- **Gas优化**: 使用高效的存储和计算模式
- **安全审计**: 遵循OpenZeppelin安全标准

### 前端特性

- **React + TypeScript**: 类型安全的前端开发
- **Wagmi + Viem**: 现代Web3开发栈
- **响应式设计**: 支持移动端和桌面端
- **实时更新**: 自动同步链上状态

---

## 🔮 未来规划

### v5版本计划
- [ ] 动态权重调整
- [ ] 收益农场集成
- [ ] 跨链支持
- [ ] DAO治理集成

### 生态扩展
- [ ] 更多成分代币支持
- [ ] 机构级功能
- [ ] 风险评级系统
- [ ] 保险机制

---

*本文档持续更新中，最新版本请查看项目仓库。*