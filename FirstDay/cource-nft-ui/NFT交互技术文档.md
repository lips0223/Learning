# Course NFT UI 技术文档

## 项目概述

这是一个基于 React + TypeScript + Vite 构建的去中心化应用（DApp），实现了课程门票NFT的购买、核销和推荐返佣功能。项目使用 RainbowKit + Wagmi 技术栈来实现钱包连接和区块链交互。

## 技术栈

### 核心依赖
- **React 18.3.1** - 前端UI框架
- **TypeScript** - 类型安全
- **Vite** - 构建工具
- **@rainbow-me/rainbowkit 2.2.0** - 钱包连接UI组件
- **wagmi 2.12.25** - 以太坊React hooks库
- **viem 2.21.34** - 底层以太坊客户端
- **@tanstack/react-query 5.59.16** - 异步状态管理

### 项目结构
```
src/
├── App.tsx                 # 应用入口组件
├── main.tsx               # React应用挂载点
├── components/
│   ├── Web3Provider.tsx   # Web3配置和Provider组件
│   ├── CourceNFT.tsx     # 主业务组件
│   ├── Approve.tsx       # USDT授权组件
│   ├── BuyNFT.tsx        # NFT购买组件
│   ├── Consume.tsx       # NFT核销组件
│   ├── Referral.tsx      # 推荐返佣组件
│   └── Constants.tsx     # 合约地址常量
├── abis/
│   ├── courceNFT.ts      # 课程NFT合约ABI
│   └── usdt.ts           # USDT合约ABI
└── assets/               # 静态资源
```

## 核心功能实现

### 1. Web3 配置和钱包连接

#### Web3Provider.tsx - 配置层
```tsx
import "@rainbow-me/rainbowkit/styles.css";
import {
  getDefaultConfig,
  RainbowKitProvider,
  ConnectButton,
} from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { arbitrum } from "wagmi/chains";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";

const config = getDefaultConfig({
  appName: "CourceNFT",
  projectId: "5389107099f8225b488f2fc473658a62", // WalletConnect项目ID
  chains: [arbitrum], // 仅支持Arbitrum网络
  ssr: true,
});

const queryClient = new QueryClient();
```

**技术要点：**
- 使用 `getDefaultConfig` 快速配置钱包连接
- 限制网络为 Arbitrum（Chain ID: 42161）
- 集成 React Query 用于状态管理
- 提供三层Provider嵌套：WagmiProvider → QueryClientProvider → RainbowKitProvider

#### 钱包连接按钮
```tsx
<ConnectButton />
```
RainbowKit 提供的即插即用连接按钮，支持多种钱包（MetaMask、WalletConnect、Coinbase等）

### 2. 合约地址和ABI管理

#### Constants.tsx - 地址管理
```tsx
import { getAddress } from "viem";

const usdtAddress = getAddress("0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9");
const courceNftAddress = getAddress("0xFF86A1f61a68496A3B1111696808459098C49b29");
```

**技术要点：**
- 使用 `viem` 的 `getAddress` 函数进行地址校验和格式化
- 统一管理合约地址，便于维护

#### ABI（Application Binary Interface）详解

**什么是ABI？**
ABI是智能合约的应用程序二进制接口，它定义了如何与智能合约进行交互。包含：
- 函数签名和参数类型
- 事件定义
- 错误类型定义
- 状态可变性（view、pure、nonpayable、payable）

**项目中的ABI文件组织：**
```
src/abis/
├── courceNFT.ts      # 课程NFT合约ABI (721行)
└── usdt.ts           # USDT代币合约ABI (459行)
```

#### 1. Course NFT 合约 ABI 分析

**核心业务函数：**
```typescript
// 购买NFT - 核心业务函数
{
  inputs: [{ internalType: "address", name: "referrer", type: "address" }],
  name: "buy",
  outputs: [],
  stateMutability: "nonpayable",
  type: "function",
}

// NFT核销功能
{
  inputs: [
    { internalType: "uint256", name: "tokenId", type: "uint256" },
    { internalType: "uint256", name: "code", type: "uint256" },
  ],
  name: "consume",
  outputs: [],
  stateMutability: "nonpayable",
  type: "function",
}

// 领取推荐佣金
{
  inputs: [],
  name: "claimCommission",
  outputs: [],
  stateMutability: "nonpayable",
  type: "function",
}
```

**查询函数（view/pure）：**
```typescript
// 查询NFT价格
{
  inputs: [],
  name: "price",
  outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
  stateMutability: "view",
  type: "function",
}

// 查询推荐人佣金比例
{
  inputs: [{ internalType: "address", name: "", type: "address" }],
  name: "referrerCommissionRatio",
  outputs: [{ internalType: "uint24", name: "", type: "uint24" }],
  stateMutability: "view",
  type: "function",
}

// 查询可领取佣金
{
  inputs: [{ internalType: "address", name: "", type: "address" }],
  name: "referrerCommission",
  outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
  stateMutability: "view",
  type: "function",
}
```

**重要事件定义：**
```typescript
// 购买成功事件
{
  anonymous: false,
  inputs: [
    { indexed: true, internalType: "address", name: "sender", type: "address" },
    { indexed: true, internalType: "address", name: "referrer", type: "address" },
    { indexed: false, internalType: "uint256", name: "tokenId", type: "uint256" },
    { indexed: false, internalType: "uint256", name: "price", type: "uint256" },
    { indexed: false, internalType: "uint256", name: "commission", type: "uint256" },
  ],
  name: "Bought",
  type: "event",
}

// NFT核销事件
{
  anonymous: false,
  inputs: [
    { indexed: true, internalType: "address", name: "sender", type: "address" },
    { indexed: false, internalType: "uint256", name: "tokenId", type: "uint256" },
    { indexed: false, internalType: "uint256", name: "code", type: "uint256" },
  ],
  name: "Consumed",
  type: "event",
}
```

#### 2. USDT 合约 ABI 分析

**ERC20标准函数：**
```typescript
// 授权额度查询
{
  inputs: [
    { internalType: "address", name: "owner", type: "address" },
    { internalType: "address", name: "spender", type: "address" },
  ],
  name: "allowance",
  outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
  stateMutability: "view",
  type: "function",
}

// 授权操作
{
  inputs: [
    { internalType: "address", name: "spender", type: "address" },
    { internalType: "uint256", name: "amount", type: "uint256" },
  ],
  name: "approve",
  outputs: [{ internalType: "bool", name: "", type: "bool" }],
  stateMutability: "nonpayable",
  type: "function",
}

// 余额查询
{
  inputs: [{ internalType: "address", name: "account", type: "address" }],
  name: "balanceOf",
  outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
  stateMutability: "view",
  type: "function",
}
```

#### 3. ABI 在 Wagmi 中的使用

**读取合约数据：**
```tsx
const { data } = useReadContract({
  address: courceNftAddress,  // 合约地址
  abi: courceNftAbi,         // 合约ABI
  functionName: "price",      // 函数名（必须在ABI中定义）
});
```

**写入合约数据：**
```tsx
const { writeContractAsync } = useWriteContract();

await writeContractAsync({
  abi: courceNftAbi,         // ABI定义了函数签名
  address: courceNftAddress,  // 目标合约地址
  functionName: "buy",        // 调用的函数名
  args: [referrer],          // 参数数组，类型必须匹配ABI定义
});
```

#### 4. ABI 类型安全

**TypeScript 类型推断：**
- Wagmi 会根据 ABI 自动推断函数参数类型
- 编译时检查函数名和参数类型
- 返回值类型自动推断

**示例 - 类型安全的合约调用：**
```tsx
// TypeScript 会检查参数类型
const { data } = useReadContract({
  abi: courceNftAbi,
  address: courceNftAddress,
  functionName: "referrerCommissionRatio", // 必须存在于ABI中
  args: [address], // 类型必须是 address
});

// data 类型自动推断为 uint24 | undefined
```

#### 5. ABI 获取和管理最佳实践

**1. ABI 文件组织：**
```typescript
// abis/courceNFT.ts
export const courceNftAbi = [
  // ... ABI 定义
] as const; // 使用 as const 确保类型推断

// 导出常用的类型
export type CourseNFTAbi = typeof courceNftAbi;
```

**2. 合约对象模式：**
```typescript
// 统一的合约配置对象
const courceNftContract = {
  abi: courceNftAbi,
  address: courceNftAddress,
} as const;

// 在组件中复用
const { data } = useReadContract({
  ...courceNftContract,
  functionName: "price",
});
```

**3. ABI 版本管理：**
- 每次合约升级都应该更新对应的 ABI
- 使用版本号管理不同版本的 ABI
- 在部署时验证 ABI 与链上合约的一致性

#### 6. 错误类型定义

**合约错误在 ABI 中的定义：**
```typescript
// 自定义错误类型
{
  inputs: [{ internalType: "address", name: "account", type: "address" }],
  name: "OwnableUnauthorizedAccount",
  type: "error",
},
{
  inputs: [],
  name: "ReentrancyGuardReentrantCall",
  type: "error",
}
```

**错误处理：**
```tsx
const { error } = useWriteContract();

// Wagmi 会自动解析合约错误
if (error) {
  // 错误信息包含具体的合约错误类型
  console.log("Contract Error:", error.message);
}
```

### 3. 核心业务逻辑实现

#### 3.1 账户状态管理

```tsx
import { useAccount } from "wagmi";

export const CourceNFT = () => {
  const { address, isConnected } = useAccount();
  
  return (
    <div>
      {isConnected ? (
        <div>
          {/* 业务组件 */}
        </div>
      ) : (
        <h2>请先Connect Wallet</h2>
      )}
    </div>
  );
};
```

**使用的 Wagmi Hook：**
- `useAccount()`: 获取当前连接的钱包地址和连接状态

#### 3.2 合约数据读取

**价格查询示例：**
```tsx
import { useReadContract } from "wagmi";

const { data, refetch } = useReadContract({
  address: courceNftAddress,
  abi: courceNftAbi,
  functionName: "price",
});

// 定时刷新数据
useEffect(() => {
  const interval = setInterval(() => {
    refetch(); // 手动触发重新读取
  }, 10000); // 10秒刷新一次
  
  return () => clearInterval(interval);
}, [refetch]);
```

**使用的 Wagmi Hook：**
- `useReadContract()`: 读取合约状态数据
  - 返回 `data`（读取结果）
  - 返回 `refetch`（手动重新读取函数）

#### 3.3 USDT授权流程（Approve.tsx）

**查询授权额度：**
```tsx
const { data: allowanceData, refetch } = useReadContract({
  abi: usdtAbi,
  address: usdtAddress,
  functionName: "allowance",
  args: [address, courceNftAddress], // [owner, spender]
});
```

**执行授权操作：**
```tsx
import { useWriteContract } from "wagmi";

const {
  data: hash,
  writeContractAsync: approve,
  isSuccess,
  error,
} = useWriteContract();

const handleApprove = () => {
  if (approve) {
    approve({
      abi: usdtAbi,
      address: usdtAddress,
      functionName: "approve",
      args: [courceNftAddress, price], // [spender, amount]
    });
  }
};

// 监听交易成功，刷新授权额度
useEffect(() => {
  if (isSuccess) {
    setTimeout(() => {
      refetch(); // 重新读取授权额度
    }, 1000);
  }
}, [isSuccess, refetch]);
```

**使用的 Wagmi Hook：**
- `useWriteContract()`: 执行合约写入操作
  - 返回 `writeContractAsync`（异步执行函数）
  - 返回 `data`（交易哈希）
  - 返回 `isSuccess`（交易成功状态）
  - 返回 `error`（错误信息）

#### 3.4 NFT购买流程（BuyNFT.tsx）

**余额检查：**
```tsx
const { data: balanceData } = useReadContract({
  abi: usdtAbi,
  address: usdtAddress,
  functionName: "balanceOf",
  args: [address],
});

useEffect(() => {
  if (balanceData && typeof balanceData === "bigint") {
    setBalanceString((balanceData / BigInt(1000000)).toString());
    setEnoughBalance(balanceData >= price);
  }
}, [balanceData, price]);
```

**推荐人验证：**
```tsx
const { refetch } = useReadContract({
  abi: courceNftAbi,
  address: courceNftAddress,
  functionName: "referrerCommissionRatio",
  args: [referrer],
});

const checkReferrer = async () => {
  const { data } = await refetch();
  if (data && typeof data === "number" && data > 0) {
    alert("推荐人有效");
  } else {
    alert("无效的推荐人地址");
  }
};
```

**执行购买：**
```tsx
const { data: hash, writeContractAsync: buy, error } = useWriteContract();

const handleBuy = () => {
  if (buy) {
    buy({
      abi: courceNftAbi,
      address: courceNftAddress,
      functionName: "buy",
      args: [referrer], // 推荐人地址
    });
  }
};
```

#### 3.5 NFT核销流程（Consume.tsx）

**获取用户持有的NFT：**
```tsx
const { data: tokenIdData } = useReadContract({
  abi: courceNftAbi,
  address: courceNftAddress,
  functionName: "tokenOfOwnerByIndex",
  args: [address, 0], // 获取用户第一个NFT的tokenId
});
```

**执行核销：**
```tsx
const { data: hash, writeContractAsync: consume, error } = useWriteContract();

const handleConsume = () => {
  if (consume) {
    consume({
      abi: courceNftAbi,
      address: courceNftAddress,
      functionName: "consume",
      args: [tokenId, code], // [NFT ID, 核销码]
    });
  }
};
```

#### 3.6 推荐返佣系统（Referral.tsx）

**查询返佣比例和金额：**
```tsx
const courceNftContract = {
  abi: courceNftAbi,
  address: courceNftAddress,
};

// 返佣比例查询
const { data: ratioData, refetch: refetchRatio } = useReadContract({
  ...courceNftContract,
  functionName: "referrerCommissionRatio",
  args: [address],
});

// 可领取佣金查询
const { data: commissionData, refetch: refetchCommission } = useReadContract({
  ...courceNftContract,
  functionName: "referrerCommission",
  args: [address],
});
```

**领取佣金：**
```tsx
const {
  data: hash,
  writeContractAsync: claim,
  isSuccess,
  error,
} = useWriteContract();

const handleClaim = () => {
  if (claim) {
    claim({
      ...courceNftContract,
      functionName: "claimCommission",
    });
  }
};

// 领取成功后刷新数据
useEffect(() => {
  if (isSuccess) {
    setTimeout(() => {
      refetchRatio();
      refetchCommission();
    }, 1000);
  }
}, [isSuccess, refetchRatio, refetchCommission]);
```

## Wagmi Hooks 完整使用总结

### 1. 账户管理
- `useAccount()`: 获取连接状态、钱包地址等账户信息

### 2. 合约读取
- `useReadContract()`: 读取合约状态数据
  - 支持自动缓存和重新验证
  - 提供 `refetch` 函数手动刷新
  - 返回 `data`, `isLoading`, `error` 等状态

### 3. 合约写入
- `useWriteContract()`: 执行合约交易
  - 返回 `writeContractAsync` 异步执行函数
  - 返回 `data` (交易哈希)
  - 返回 `isSuccess`, `isPending`, `error` 等状态
  - 支持交易确认监听

## 数据流和状态管理

### 1. 状态更新流程
```
用户操作 → Wagmi Hook → 区块链交易 → 交易确认 → 状态刷新 → UI更新
```

### 2. 错误处理
- 所有 Wagmi hooks 都提供 `error` 状态
- 统一在UI层展示错误信息
- 支持交易失败重试

### 3. 加载状态
- 使用 `isPending` 状态显示加载中
- 交易提交后显示交易哈希
- 链接到区块浏览器查看详情

## 用户交互流程

### 完整购买流程
1. **连接钱包** - 使用 RainbowKit ConnectButton
2. **检查余额** - 读取用户USDT余额
3. **USDT授权** - 授权NFT合约使用USDT
4. **购买NFT** - 调用buy函数，可选填入推荐人
5. **核销NFT** - 输入tokenId和核销码完成核销

### 推荐返佣流程
1. **成为推荐人** - 具有返佣比例的地址
2. **推广链接** - 其他用户使用你的地址作为推荐人购买
3. **累积佣金** - 系统自动计算佣金
4. **领取佣金** - 调用claimCommission领取USDT

## 部署和配置

### 环境要求
- Node.js 16+
- 支持WalletConnect的钱包

### 网络配置
- 主网：Arbitrum One (Chain ID: 42161)
- 合约地址已硬编码在Constants.tsx中

### 核心配置项
- **WalletConnect Project ID**: 用于钱包连接
- **合约地址**: USDT和课程NFT合约地址
- **网络设置**: 限制为Arbitrum网络

## 安全考虑

### 1. 合约交互安全
- 所有地址使用 `viem.getAddress()` 进行校验
- 金额计算使用 `BigInt` 避免精度问题
- 交易前进行余额和授权检查

### 2. 用户体验优化
- 实时显示交易状态和错误信息
- 提供区块浏览器链接查看交易详情
- 自动刷新合约状态数据

### 3. 错误处理
- 完整的错误边界处理
- 用户友好的错误提示
- 支持交易失败重试

## 总结

该项目展示了现代DApp开发的最佳实践：

1. **技术栈现代化** - 使用最新的React、TypeScript、Wagmi生态
2. **用户体验优秀** - RainbowKit提供丝滑的钱包连接体验
3. **代码结构清晰** - 组件化开发，职责分离
4. **状态管理完善** - 结合React Query和Wagmi实现高效的异步状态管理
5. **错误处理全面** - 完整的错误边界和用户提示
6. **安全性考虑** - 地址校验、类型安全、交易确认

这个项目可以作为Web3应用开发的参考模板，特别适合NFT交易、DeFi应用等场景。
