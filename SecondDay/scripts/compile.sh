#!/bin/bash

# ETF 合约编译和扁平化脚本
# 作者: GitHub Copilot
# 用途: 编译所有 ETF 合约并生成扁平化文件用于部署

set -e

echo "🚀 开始编译 ETF 合约系统..."

# 检查是否安装了 Foundry
if ! command -v forge &> /dev/null; then
    echo "❌ 错误: 未找到 Forge，请先安装 Foundry"
    echo "安装命令: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

# 创建输出目录
OUTPUT_DIR="./flattened"
mkdir -p $OUTPUT_DIR

echo "📁 创建输出目录: $OUTPUT_DIR"

# 清理之前的编译结果
echo "🧹 清理之前的编译结果..."
forge clean

# 安装依赖（如果需要）
echo "📦 安装依赖..."
if [ -f "package.json" ]; then
    npm install
fi

# 编译所有合约
echo "🔨 编译合约..."
forge build

if [ $? -eq 0 ]; then
    echo "✅ 合约编译成功!"
else
    echo "❌ 合约编译失败!"
    exit 1
fi

# 扁平化函数
flatten_contract() {
    local contract_path=$1
    local contract_name=$2
    local output_file="$OUTPUT_DIR/${contract_name}_flattened.sol"
    
    echo "📄 正在扁平化: $contract_name"
    
    if forge flatten $contract_path > $output_file; then
        echo "✅ $contract_name 扁平化完成: $output_file"
    else
        echo "❌ $contract_name 扁平化失败"
        return 1
    fi
}

# 扁平化所有主要合约
echo "📋 开始扁平化合约..."

# ETFv1 相关合约
echo "🔄 处理 ETFv1 合约..."
flatten_contract "contracts/src/ETFv1/ETFv1.sol" "ETFv1"

# ETFv2 相关合约
echo "🔄 处理 ETFv2 合约..."
flatten_contract "contracts/src/ETFv2/ETFv2.sol" "ETFv2"

# MockToken 合约（用于测试）
if [ -f "contracts/MockToken.sol" ]; then
    flatten_contract "contracts/MockToken.sol" "MockToken"
fi

echo "📊 生成编译报告..."

# 创建编译报告
REPORT_FILE="$OUTPUT_DIR/compilation_report.md"
cat > $REPORT_FILE << EOF
# ETF 合约编译报告

生成时间: $(date)

## 编译配置
- Solidity 版本: 0.8.24
- 优化器: 启用 (200 runs)
- 目标网络: Sepolia Testnet

## 已编译合约

### ETFv1 系列
- ✅ ETFv1.sol
  - 文件: ETFv1_flattened.sol
  - 功能: 基础 ETF 投资和赎回

### ETFv2 系列  
- ✅ ETFv2.sol
  - 文件: ETFv2_flattened.sol
  - 功能: ETH 投资，Uniswap 集成

### 工具合约
- ✅ MockToken.sol (如果存在)
  - 文件: MockToken_flattened.sol
  - 功能: 测试用代币

## 部署说明

1. 使用扁平化文件在 Remix 或其他 IDE 中部署
2. 部署顺序:
   - 先部署 MockToken (测试用)
   - 再部署 ETFv1
   - 最后部署 ETFv2

3. 验证合约时使用对应的扁平化文件

## 下一步
- 配置环境变量
- 在 Sepolia 测试网部署
- 验证合约源码
- 更新前端配置

EOF

echo "📈 编译统计信息:"
echo "- 扁平化文件数量: $(ls -1 $OUTPUT_DIR/*.sol 2>/dev/null | wc -l)"
echo "- 输出目录大小: $(du -sh $OUTPUT_DIR | cut -f1)"

echo ""
echo "🎉 编译和扁平化完成!"
echo "📁 扁平化文件位置: $OUTPUT_DIR"
echo "📋 编译报告: $REPORT_FILE"
echo ""
echo "下一步:"
echo "1. 检查扁平化文件"
echo "2. 配置部署参数"
echo "3. 执行部署脚本"
echo ""

# 显示扁平化文件列表
echo "📋 生成的扁平化文件:"
ls -la $OUTPUT_DIR/*.sol 2>/dev/null || echo "没有找到扁平化文件"