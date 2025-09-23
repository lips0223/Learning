// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/**
 * @title Path 库
 * @dev 用于处理 Uniswap V3 多跳交换路径的工具库
 * @notice 路径格式: token0 → fee0 → token1 → fee1 → token2 ...
 */
library Path {
    using BytesLib for bytes;

    // ============== 常量定义 ==============
    uint256 private constant ADDR_SIZE = 20;        // 地址字节长度
    uint256 private constant FEE_SIZE = 3;          // 手续费字节长度
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;  // 单个跳跃的偏移量
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE; // 弹出一个池子的偏移量
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET; // 多池最小长度

    /**
     * @dev 检查路径是否包含多个池子
     * @param path 编码的交换路径
     * @return 如果包含多个池子返回true，否则返回false
     */
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /**
     * @dev 返回路径中池子的数量
     * @param path 编码的交换路径
     * @return 池子数量
     */
    function numPools(bytes memory path) internal pure returns (uint256) {
        // 忽略第一个代币地址，从那之后每个手续费和代币偏移表示一个池子
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /**
     * @dev 解码路径中的第一个池子
     * @param path 编码的交换路径
     * @return tokenA 第一个代币地址
     * @return tokenB 第二个代币地址  
     * @return fee 池子的手续费等级
     */
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);                    // 第一个代币地址
        fee = path.toUint24(ADDR_SIZE);               // 手续费
        tokenB = path.toAddress(NEXT_OFFSET);         // 第二个代币地址
    }

    /**
     * @dev 获取路径中的第一个代币地址
     * @param path 编码的交换路径
     * @return tokenA 第一个代币地址
     */
    function getFirstToken(bytes memory path) internal pure returns (address tokenA) {
        tokenA = path.toAddress(0);
    }

    /**
     * @dev 获取路径中的最后一个代币地址
     * @param path 编码的交换路径
     * @return tokenB 最后一个代币地址
     */
    function getLastToken(bytes memory path) internal pure returns (address tokenB) {
        tokenB = path.toAddress(path.length - ADDR_SIZE);
    }

    /**
     * @dev 获取路径中第一个池子的手续费等级
     * @param path 编码的交换路径
     * @return fee 第一个池子的手续费等级
     */
    function getFirstFee(bytes memory path) internal pure returns (uint24 fee) {
        fee = path.toUint24(ADDR_SIZE);
    }

    /**
     * @dev 跳过路径中的第一个代币，返回剩余路径
     * @param path 编码的交换路径
     * @return 去掉第一个代币的路径
     */
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }

    /**
     * @dev 验证路径格式是否正确
     * @param path 编码的交换路径
     * @return 路径是否有效
     */
    function isValidPath(bytes memory path) internal pure returns (bool) {
        // 最小路径长度应该是: 地址 + 手续费 + 地址 = 20 + 3 + 20 = 43 字节
        if (path.length < ADDR_SIZE + FEE_SIZE + ADDR_SIZE) {
            return false;
        }
        
        // 检查路径长度是否符合格式要求
        // 应该是: 20 + (23 * n) 其中 n >= 1
        return (path.length - ADDR_SIZE) % NEXT_OFFSET == 0;
    }

    /**
     * @dev 反转路径（用于反向交换）
     * @param path 原始路径
     * @return 反转后的路径
     */
    function reversePath(bytes memory path) internal pure returns (bytes memory) {
        require(isValidPath(path), "Invalid path");
        
        uint256 numPoolsInPath = numPools(path);
        bytes memory reversedPath = new bytes(path.length);
        
        // 反转路径：将最后一个代币放到开头，第一个代币放到最后
        uint256 writeIndex = 0;
        
        // 写入最后一个代币
        bytes memory lastToken = path.slice(path.length - ADDR_SIZE, ADDR_SIZE);
        for (uint256 i = 0; i < ADDR_SIZE; i++) {
            reversedPath[writeIndex++] = lastToken[i];
        }
        
        // 反向写入每个池子的手续费和代币
        for (uint256 i = numPoolsInPath; i > 0; i--) {
            uint256 poolStartIndex = ADDR_SIZE + (i - 1) * NEXT_OFFSET;
            
            // 写入手续费
            bytes memory fee = path.slice(poolStartIndex, FEE_SIZE);
            for (uint256 j = 0; j < FEE_SIZE; j++) {
                reversedPath[writeIndex++] = fee[j];
            }
            
            // 写入代币地址
            bytes memory token = path.slice(poolStartIndex - ADDR_SIZE, ADDR_SIZE);
            for (uint256 j = 0; j < ADDR_SIZE; j++) {
                reversedPath[writeIndex++] = token[j];
            }
        }
        
        return reversedPath;
    }
}