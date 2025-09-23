# ETF智能合约系统

## 📚 项目概述

这是一个完整的ETF（Exchange Traded Fund）智能合约系统，基于以太坊区块链构建，支持多种投资策略和可升级架构。

### 🚀 主要特性

- **多版本ETF合约**: ETFv1-v4，功能逐步增强
- **ETH直接投资**: 通过Uniswap V3自动兑换
- **动态再平衡**: 支持投资组合权重调整
- **流动性挖矿**: 持有ETF获得代币奖励
- **可升级架构**: UUPS代理模式支持合约升级
- **批量部署**: 工厂合约支持批量创建ETF

## 📁 项目结构

```
contracts/
├── src/                          # 源代码
│   ├── ETFv1/                   # 基础ETF合约
│   ├── ETFv2/                   # ETH投资版本
│   ├── ETFv3/                   # 动态再平衡版本
│   ├── ETFv4/                   # 挖矿奖励版本
│   ├── ETF-Upgradeable/         # 可升级版本
│   └── MockToken/               # 测试代币
├── script/                       # 部署脚本
├── test/                        # 测试文件
├── flattened/                   # 扁平化合约
├── ETF_DEPLOYMENT_SUMMARY.md    # 部署总结
├── CONTRACT_INTERACTION_GUIDE.md # 交互指南
└── verify_contracts.sh          # 验证脚本
```

## 🔗 部署地址 (Sepolia)

| 合约 | 地址 | 功能 |
|------|------|------|
| ETFv1 | `0x37Ee135db8e41D3F9C15F97918C58651E8A564A6` | 基础ETF功能 |
| ETFv2 | `0xe75dDeb4d90F62b0D70CAFe2c8db9B968E29336c` | ETH投资功能 |
| ETFv3Lite | `0xF5cF61a03c562f254501C0693B67B31cAa79Df4C` | 动态再平衡 |
| ETFv4Lite | `0xa02A55F8c4DA1271C37D13C90A372747295B5a60` | 挖矿奖励 |
| ETFProtocolToken | `0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499` | 协议代币 |
| ETFUUPSUpgradeable | `0xEb8f4136578538758eAf2a382E9cB30D897dd958` | 可升级实现 |
| ETFProxyFactory | `0x7DD6d4f5507DB3e448FC64d78C37F7A687F27405` | 代理工厂 |

## 🛠 快速开始

### 环境要求

- **Foundry**: Solidity开发工具链
- **Node.js**: JavaScript运行环境  
- **Python**: Python交互支持

### 安装依赖

```bash
# 克隆项目
git clone <repository_url>
cd contracts

# 安装Foundry依赖
forge install

# 设置环境变量
export PRIVATE_KEY="your_private_key"
export SEPOLIA_RPC_URL="your_sepolia_rpc_url"
export ETHERSCAN_API_KEY="your_etherscan_api_key"
```

## 📖 文档

- **[部署总结](./ETF_DEPLOYMENT_SUMMARY.md)**: 详细的合约信息和部署记录
- **[交互指南](./CONTRACT_INTERACTION_GUIDE.md)**: JavaScript/Python交互示例
- **[验证脚本](./verify_contracts.sh)**: 自动化合约验证

## Foundry 使用指南

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
