// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IETFv1} from "./IETFv1.sol";

/**
 * @title IETFv2 接口
 * @dev ETFv2合约的接口定义，继承自IETFv1并添加了ETH投资相关功能
 */
interface IETFv2 is IETFv1 {
    // ============== 错误定义 ==============
    error InvalidSwapPath(bytes path);  // 无效的交换路径
    error InvalidArrayLength();         // 数组长度不匹配
    error ExceedsMaxETHAmount();        // 超出最大ETH数量
    error InsufficientETHAmount();      // ETH数量不足
    error TransferFailed();             // 转账失败
    error OverSlippage();               // 超出滑点限制
    error SafeTransferETHFailed();      // ETH转账失败

    // ============== 事件定义 ==============
    
    /**
     * @dev ETH投资事件
     * @param to 接收ETF份额的地址
     * @param mintAmount 铸造的ETF份额数量
     * @param paidAmount 实际支付的ETH数量
     */
    event InvestedWithETH(
        address indexed to, 
        uint256 mintAmount, 
        uint256 paidAmount
    );
    
    /**
     * @dev 代币投资事件
     * @param srcToken 源代币地址
     * @param to 接收ETF份额的地址
     * @param mintAmount 铸造的ETF份额数量
     * @param paidAmount 实际支付的代币数量
     */
    event InvestedWithToken(
        address indexed srcToken,
        address indexed to, 
        uint256 mintAmount, 
        uint256 paidAmount
    );
    
    /**
     * @dev ETH赎回事件  
     * @param to 接收ETH的地址
     * @param burnAmount 销毁的ETF份额数量
     * @param receivedAmount 接收的ETH数量
     */
    event RedeemedToETH(
        address indexed to, 
        uint256 burnAmount, 
        uint256 receivedAmount
    );
    
    /**
     * @dev 代币赎回事件
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 销毁的ETF份额数量
     * @param receivedAmount 接收的代币数量
     */
    event RedeemedToToken(
        address indexed dstToken,
        address indexed to, 
        uint256 burnAmount, 
        uint256 receivedAmount
    );

        // ============== 函数接口 ==============
    
    /**
     * @dev 使用ETH投资ETF
     * @param to 接收ETF份额的地址
     * @param mintAmount 要铸造的ETF份额数量
     * @param swapPaths Uniswap交换路径数组
     */
    function investWithETH(
        address to,
        uint256 mintAmount,
        bytes[] memory swapPaths
    ) external payable;

    /**
     * @dev 使用指定代币投资ETF
     * @param srcToken 源代币地址
     * @param to 接收ETF份额的地址
     * @param mintAmount 要铸造的ETF份额数量
     * @param maxSrcTokenAmount 最大源代币数量
     * @param swapPaths Uniswap交换路径数组
     */
    function investWithToken(
        address srcToken,
        address to,
        uint256 mintAmount,
        uint256 maxSrcTokenAmount,
        bytes[] memory swapPaths
    ) external;

    /**
     * @dev 赎回ETF获得ETH
     * @param to 接收ETH的地址
     * @param burnAmount 要销毁的ETF份额数量
     * @param minETHAmount 最小接收ETH数量
     * @param swapPaths Uniswap交换路径数组
     */
    function redeemToETH(
        address to,
        uint256 burnAmount,
        uint256 minETHAmount,
        bytes[] memory swapPaths
    ) external;

    /**
     * @dev 赎回ETF获得指定代币
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的ETF份额数量
     * @param minDstTokenAmount 最小接收代币数量
     * @param swapPaths Uniswap交换路径数组
     */
    function redeemToToken(
        address dstToken,
        address to,
        uint256 burnAmount,
        uint256 minDstTokenAmount,
        bytes[] memory swapPaths
    ) external;
}