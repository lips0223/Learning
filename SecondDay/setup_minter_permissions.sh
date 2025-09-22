#!/bin/bash

# 设置 minter 权限脚本
# TokenAirDrop 合约地址
TOKEN_AIRDROP_CONTRACT="0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569"

# RPC URL
RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"

# 私钥 (确保这个私钥对应的地址是代币合约的 owner)
PRIVATE_KEY="0x7ad968ae67253103d1357aefec508469e7e88a4566233b30f100e4498e4ffa4b"

echo "开始为所有代币合约设置 minter 权限..."

# USDC 合约
echo "设置 USDC minter 权限..."
cast send 0x279b091df8fd4a07a01231dcfea971d2abcae0f8 \
  "addMinter(address)" \
  $TOKEN_AIRDROP_CONTRACT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# USDT 合约
echo "设置 USDT minter 权限..."
cast send 0xda988ddbbb4797affe6efb1b267b7d4b29b604eb \
  "addMinter(address)" \
  $TOKEN_AIRDROP_CONTRACT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# LINK 合约
echo "设置 LINK minter 权限..."
cast send 0x1847d3dba09a81e74b31c1d4c9d3220452ab3973 \
  "addMinter(address)" \
  $TOKEN_AIRDROP_CONTRACT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# UNI 合约
echo "设置 UNI minter 权限..."
cast send 0x237b68901458be70498b923a943de7f885c89943 \
  "addMinter(address)" \
  $TOKEN_AIRDROP_CONTRACT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

echo "所有权限设置完成！"

# 验证权限
echo "验证权限设置..."
echo "WBTC minter 权限: $(cast call 0x550a3fc779b68919b378c1925538af7065a2a761 "minters(address)" $TOKEN_AIRDROP_CONTRACT --rpc-url $RPC_URL)"
echo "USDC minter 权限: $(cast call 0x279b091df8fd4a07a01231dcfea971d2abcae0f8 "minters(address)" $TOKEN_AIRDROP_CONTRACT --rpc-url $RPC_URL)"
echo "USDT minter 权限: $(cast call 0xda988ddbbb4797affe6efb1b267b7d4b29b604eb "minters(address)" $TOKEN_AIRDROP_CONTRACT --rpc-url $RPC_URL)"
echo "LINK minter 权限: $(cast call 0x1847d3dba09a81e74b31c1d4c9d3220452ab3973 "minters(address)" $TOKEN_AIRDROP_CONTRACT --rpc-url $RPC_URL)"
echo "UNI minter 权限:  $(cast call 0x237b68901458be70498b923a943de7f885c89943 "minters(address)" $TOKEN_AIRDROP_CONTRACT --rpc-url $RPC_URL)"