// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IV3SwapRouter 接口
 * @dev Uniswap V3 SwapRouter 合约接口，用于代币交换
 */
interface IV3SwapRouter {
    /**
     * @dev 精确输入单笔交换参数结构
     */
    struct ExactInputSingleParams {
        address tokenIn;           // 输入代币地址
        address tokenOut;          // 输出代币地址
        uint24 fee;               // 手续费等级
        address recipient;         // 接收地址
        uint256 deadline;          // 交易截止时间
        uint256 amountIn;          // 输入代币数量
        uint256 amountOutMinimum;  // 最小输出代币数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    /**
     * @dev 精确输出单笔交换参数结构
     */
    struct ExactOutputSingleParams {
        address tokenIn;           // 输入代币地址
        address tokenOut;          // 输出代币地址
        uint24 fee;               // 手续费等级
        address recipient;         // 接收地址
        uint256 deadline;          // 交易截止时间
        uint256 amountOut;         // 输出代币数量
        uint256 amountInMaximum;   // 最大输入代币数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    /**
     * @dev 精确输入多跳交换参数结构
     */
    struct ExactInputParams {
        bytes path;               // 交换路径
        address recipient;        // 接收地址
        uint256 deadline;         // 交易截止时间
        uint256 amountIn;         // 输入代币数量
        uint256 amountOutMinimum; // 最小输出代币数量
    }

    /**
     * @dev 精确输出多跳交换参数结构
     */
    struct ExactOutputParams {
        bytes path;              // 交换路径
        address recipient;       // 接收地址
        uint256 deadline;        // 交易截止时间
        uint256 amountOut;       // 输出代币数量
        uint256 amountInMaximum; // 最大输入代币数量
    }

    /**
     * @dev 精确输入单笔交换
     * @param params 交换参数
     * @return amountOut 实际输出的代币数量
     */
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev 精确输出单笔交换
     * @param params 交换参数
     * @return amountIn 实际消耗的输入代币数量
     */
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    /**
     * @dev 精确输入多跳交换
     * @param params 交换参数
     * @return amountOut 实际输出的代币数量
     */
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev 精确输出多跳交换
     * @param params 交换参数
     * @return amountIn 实际消耗的输入代币数量
     */
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    /**
     * @dev 多重调用（批量执行多个函数）
     * @param deadline 截止时间
     * @param data 函数调用数据数组
     * @return results 执行结果数组
     */
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    /**
     * @dev 将合约中的代币转给指定地址
     * @param token 代币地址（address(0)表示ETH）
     * @param amountMinimum 最小转出数量
     * @param recipient 接收地址
     */
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /**
     * @dev 退还ETH
     */
    function refundETH() external payable;
}