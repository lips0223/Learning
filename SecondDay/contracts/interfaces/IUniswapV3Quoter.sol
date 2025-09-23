// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IUniswapV3Quoter 接口
 * @dev Uniswap V3 Quoter 合约接口，用于获取交换报价而不执行实际交换
 */
interface IUniswapV3Quoter {
    /**
     * @dev 精确输入报价 - 给定输入数量，计算输出数量
     * @param path 编码的交换路径（token0 -> fee -> token1 -> fee -> token2...）
     * @param amountIn 输入代币数量
     * @return amountOut 输出代币数量
     * @return sqrtPriceX96AfterList 每个池子交换后的价格
     * @return initializedTicksCrossedList 每个池子跨越的已初始化tick数量
     * @return gasEstimate 预估的gas消耗
     */
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        view
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );
    
    /**
     * @dev 精确输出报价 - 给定输出数量，计算所需输入数量
     * @param path 编码的交换路径（token0 -> fee -> token1 -> fee -> token2...）
     * @param amountOut 期望的输出代币数量
     * @return amountIn 需要的输入代币数量
     * @return sqrtPriceX96AfterList 每个池子交换后的价格
     * @return initializedTicksCrossedList 每个池子跨越的已初始化tick数量
     * @return gasEstimate 预估的gas消耗
     */
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        view
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    /**
     * @dev 单池精确输入报价
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param fee 池子手续费等级
     * @param amountIn 输入代币数量
     * @param sqrtPriceLimitX96 价格限制
     * @return amountOut 输出代币数量
     * @return sqrtPriceX96After 交换后的价格
     * @return initializedTicksCrossed 跨越的已初始化tick数量
     * @return gasEstimate 预估的gas消耗
     */
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    )
        external
        view
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /**
     * @dev 单池精确输出报价
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param fee 池子手续费等级
     * @param amountOut 期望的输出代币数量
     * @param sqrtPriceLimitX96 价格限制
     * @return amountIn 需要的输入代币数量
     * @return sqrtPriceX96After 交换后的价格
     * @return initializedTicksCrossed 跨越的已初始化tick数量
     * @return gasEstimate 预估的gas消耗
     */
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    )
        external
        view
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}