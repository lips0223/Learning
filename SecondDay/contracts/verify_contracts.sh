#!/bin/bash

# ETF合约Etherscan验证脚本
# 使用方法: ./verify_contracts.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 ETF合约验证脚本${NC}"
echo "================================="

# 检查环境变量
if [[ -z "$ETHERSCAN_API_KEY" ]]; then
    echo -e "${RED}❌ 请设置 ETHERSCAN_API_KEY 环境变量${NC}"
    exit 1
fi

if [[ -z "$SEPOLIA_RPC_URL" ]]; then
    echo -e "${RED}❌ 请设置 SEPOLIA_RPC_URL 环境变量${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 环境变量检查通过${NC}"

# 合约地址定义
ETF_V1_ADDRESS="0x37Ee135db8e41D3F9C15F97918C58651E8A564A6"
ETF_V2_ADDRESS="0xe75dDeb4d90F62b0D70CAFe2c8db9B968E29336c"
ETF_V3_LITE_ADDRESS="0xF5cF61a03c562f254501C0693B67B31cAa79Df4C"
ETF_V4_LITE_ADDRESS="0xa02A55F8c4DA1271C37D13C90A372747295B5a60"
ETF_PROTOCOL_TOKEN_ADDRESS="0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499"
ETF_UUPS_UPGRADEABLE_ADDRESS="0xEb8f4136578538758eAf2a382E9cB30D897dd958"
ETF_UUPS_FACTORY_ADDRESS="0x30D63b373b0a47447cD9e4c4e10c826C4361F130"
ETF_PROXY_FACTORY_ADDRESS="0x7DD6d4f5507DB3e448FC64d78C37F7A687F27405"

# 验证函数
verify_contract() {
    local contract_name=$1
    local contract_address=$2
    local flattened_file=$3
    local contract_path=$4
    local constructor_args=$5
    
    echo -e "\n${YELLOW}🔄 验证 $contract_name...${NC}"
    
    forge verify-contract \
        --chain-id 11155111 \
        --num-of-optimizations 200 \
        --compiler-version v0.8.24+commit.e11b9ed9 \
        $contract_address \
        $flattened_file:$contract_path \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --constructor-args $constructor_args
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $contract_name 验证成功${NC}"
    else
        echo -e "${RED}❌ $contract_name 验证失败${NC}"
    fi
}

# ETFv1 验证
echo -e "\n${YELLOW}📝 准备ETFv1构造函数参数...${NC}"
ETF_V1_CONSTRUCTOR=$(cast abi-encode "constructor(string,string,address[],uint256[],uint256)" \
    "ETF Token" \
    "ETF" \
    "[0x779877A7B0D9E8603169DdbD7836e478b4624789,0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844]" \
    "[1000000000000000000,1000000000000000000,1000000000000000000]" \
    "1000000000000000")

verify_contract "ETFv1" $ETF_V1_ADDRESS "src/ETFv1/flattened/ETFv1_flattened.sol" "ETFv1" $ETF_V1_CONSTRUCTOR

# ETFv2 验证
echo -e "\n${YELLOW}📝 准备ETFv2构造函数参数...${NC}"
ETF_V2_CONSTRUCTOR=$(cast abi-encode "constructor(string,string,address[],uint256[],uint256,address,address)" \
    "ETF v2 Token" \
    "ETFv2" \
    "[0x779877A7B0D9E8603169DdbD7836e478b4624789,0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844]" \
    "[1000000000000000000,1000000000000000000,1000000000000000000]" \
    "1000000000000000" \
    "0xE592427A0AEce92De3Edee1F18E0157C05861564" \
    "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9")

verify_contract "ETFv2" $ETF_V2_ADDRESS "src/ETFv2/flattened/ETFv2_flattened.sol" "ETFv2" $ETF_V2_CONSTRUCTOR

# ETFv3Lite 验证
echo -e "\n${YELLOW}📝 准备ETFv3Lite构造函数参数...${NC}"
ETF_V3_LITE_CONSTRUCTOR=$(cast abi-encode "constructor(string,string,address[])" \
    "ETF v3 Lite Token" \
    "ETFv3L" \
    "[0x779877A7B0D9E8603169DdbD7836e478b4624789,0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844]")

verify_contract "ETFv3Lite" $ETF_V3_LITE_ADDRESS "src/ETFv3/flattened/ETFv3Lite_flattened.sol" "ETFv3Lite" $ETF_V3_LITE_CONSTRUCTOR

# ETFProtocolToken 验证
echo -e "\n${YELLOW}📝 准备ETFProtocolToken构造函数参数...${NC}"
ETF_PROTOCOL_TOKEN_CONSTRUCTOR=$(cast abi-encode "constructor()" "")

verify_contract "ETFProtocolToken" $ETF_PROTOCOL_TOKEN_ADDRESS "src/ETFv4/flattened/ETFProtocolToken_flattened.sol" "ETFProtocolToken" $ETF_PROTOCOL_TOKEN_CONSTRUCTOR

# ETFv4Lite 验证
echo -e "\n${YELLOW}📝 准备ETFv4Lite构造函数参数...${NC}"
ETF_V4_LITE_CONSTRUCTOR=$(cast abi-encode "constructor(string,string,address[],uint256[],uint256,address,address,address)" \
    "ETF v4 Lite Token" \
    "ETFv4L" \
    "[0x779877A7B0D9E8603169DdbD7836e478b4624789,0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844]" \
    "[1000000000000000000,1000000000000000000,1000000000000000000]" \
    "1000000000000000" \
    "0xE592427A0AEce92De3Edee1F18E0157C05861564" \
    "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9" \
    "0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499")

verify_contract "ETFv4Lite" $ETF_V4_LITE_ADDRESS "src/ETFv4/flattened/ETFv4Lite_flattened.sol" "ETFv4Lite" $ETF_V4_LITE_CONSTRUCTOR

# ETFUUPSUpgradeable 验证 (实现合约，无构造参数)
echo -e "\n${YELLOW}📝 准备ETFUUPSUpgradeable构造函数参数...${NC}"
ETF_UUPS_CONSTRUCTOR=$(cast abi-encode "constructor()" "")

verify_contract "ETFUUPSUpgradeable" $ETF_UUPS_UPGRADEABLE_ADDRESS "src/ETF-Upgradeable/flattened/ETFUUPSUpgradeable_flattened.sol" "ETFUUPSUpgradeable" $ETF_UUPS_CONSTRUCTOR

# ETFProxyFactory 验证
echo -e "\n${YELLOW}📝 准备ETFProxyFactory构造函数参数...${NC}"
ETF_PROXY_FACTORY_CONSTRUCTOR=$(cast abi-encode "constructor(address)" $ETF_UUPS_FACTORY_ADDRESS)

verify_contract "ETFProxyFactory" $ETF_PROXY_FACTORY_ADDRESS "src/ETF-Upgradeable/flattened/ETFProxyFactory_flattened.sol" "ETFProxyFactory" $ETF_PROXY_FACTORY_CONSTRUCTOR

echo -e "\n${GREEN}🎉 验证脚本执行完成！${NC}"
echo -e "${YELLOW}📝 请到 https://sepolia.etherscan.io 检查验证状态${NC}"

# 生成验证状态报告
echo -e "\n${YELLOW}📊 合约验证状态报告${NC}"
echo "================================="
echo "ETFv1: https://sepolia.etherscan.io/address/$ETF_V1_ADDRESS"
echo "ETFv2: https://sepolia.etherscan.io/address/$ETF_V2_ADDRESS"
echo "ETFv3Lite: https://sepolia.etherscan.io/address/$ETF_V3_LITE_ADDRESS"
echo "ETFv4Lite: https://sepolia.etherscan.io/address/$ETF_V4_LITE_ADDRESS"
echo "ETFProtocolToken: https://sepolia.etherscan.io/address/$ETF_PROTOCOL_TOKEN_ADDRESS"
echo "ETFUUPSUpgradeable: https://sepolia.etherscan.io/address/$ETF_UUPS_UPGRADEABLE_ADDRESS"
echo "ETFProxyFactory: https://sepolia.etherscan.io/address/$ETF_PROXY_FACTORY_ADDRESS"