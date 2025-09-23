// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IETFQuoter 接口
 * @dev ETF价格查询器接口，用于计算投资和赎回的代币数量和交换路径
 */
interface IETFQuoter {
    // ============== 错误定义 ==============
    error SameTokens();  // 相同代币错误

    // ============== 查询函数 ==============
    
    /**
     * @dev 获取WETH地址
     * @return WETH合约地址
     */
    function weth() external view returns (address);

    /**
     * @dev 获取USDC地址
     * @return USDC合约地址
     */
    function usdc() external view returns (address);

    /**
     * @dev 获取两个代币之间的所有可能交换路径
     * @param tokenA 源代币地址
     * @param tokenB 目标代币地址
     * @return paths 所有可能的交换路径数组
     */
    function getAllPaths(
        address tokenA,
        address tokenB
    ) external view returns (bytes[] memory paths);

    /**
     * @dev 计算使用指定代币投资ETF需要的代币数量和交换路径
     * @param etf ETF合约地址
     * @param srcToken 源代币地址（用于投资的代币）
     * @param mintAmount 要铸造的ETF份额数量
     * @return srcAmount 需要的源代币总量
     * @return swapPaths 每个ETF组成代币的交换路径数组
     */
    function quoteInvestWithToken(
        address etf,
        address srcToken,
        uint256 mintAmount
    ) external view returns (uint256 srcAmount, bytes[] memory swapPaths);

    /**
     * @dev 计算赎回ETF获得指定代币的数量和交换路径
     * @param etf ETF合约地址
     * @param dstToken 目标代币地址（要接收的代币）
     * @param burnAmount 要销毁的ETF份额数量
     * @return dstAmount 能获得的目标代币总量
     * @return swapPaths 每个ETF组成代币的交换路径数组
     */
    function quoteRedeemToToken(
        address etf,
        address dstToken,
        uint256 burnAmount
    ) external view returns (uint256 dstAmount, bytes[] memory swapPaths);

    /**
     * @dev 精确输出报价 - 指定输出代币数量，计算需要的输入代币数量
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param amountOut 期望的输出代币数量
     * @return path 最优交换路径
     * @return amountIn 需要的输入代币数量
     */
    function quoteExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (bytes memory path, uint256 amountIn);

    /**
     * @dev 精确输入报价 - 指定输入代币数量，计算能得到的输出代币数量
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param amountIn 输入代币数量
     * @return path 最优交换路径
     * @return amountOut 能得到的输出代币数量
     */
    function quoteExactIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (bytes memory path, uint256 amountOut);
}