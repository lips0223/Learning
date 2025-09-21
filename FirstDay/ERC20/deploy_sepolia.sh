#!/bin/bash

# Foundry 测试网部署脚本
# 使用前请确保：
# 1. 复制 .env.example 为 .env
# 2. 在 .env 文件中填入你的实际私钥和 RPC URL
# 3. 确保钱包中有足够的 Sepolia ETH

echo "🚀 准备部署 MockToken 到 Sepolia 测试网..."

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo "❌ 错误：.env 文件不存在"
    echo "请复制 .env.example 为 .env 并填入你的配置："
    echo "cp .env.example .env"
    exit 1
fi

# 加载环境变量
source .env

# 检查必要的环境变量
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    echo "❌ 错误：请在 .env 文件中设置正确的 PRIVATE_KEY"
    exit 1
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "❌ 错误：请在 .env 文件中设置 SEPOLIA_RPC_URL"
    exit 1
fi

echo "✅ 环境变量检查通过"
echo "📡 RPC URL: $SEPOLIA_RPC_URL"

# 执行部署
echo "🔨 开始部署合约..."
forge script script/DeploySepoliaMockToken.s.sol:DeploySepoliaMockToken \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

echo "🎉 部署完成！"
echo "📋 请查看上方输出的合约地址和 Etherscan 链接"
