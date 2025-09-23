// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入接口文件
import {IETFQuoter} from "../../interfaces/IETFQuoter.sol";
import {IETFv1} from "../../interfaces/IETFv1.sol"; 
import {IUniswapV3Quoter} from "../../interfaces/IUniswapV3Quoter.sol";
// 导入数学库
import {FullMath} from "../../libraries/FullMath.sol";
// 导入OpenZeppelin合约
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ETFQuoter ETF报价合约
 * @dev 用于计算ETF投资和赎回时所需的代币交换路径和数量
 * 通过Uniswap V3进行价格计算，支持多种交换路径优化
 */
contract ETFQuoter is IETFQuoter {
    using FullMath for uint256;

    // ==================== 状态变量 ====================
    
    /// @dev Uniswap V3支持的手续费等级
    uint24[4] public fees;
    
    /// @dev WETH代币地址（作为中间代币）
    address public immutable weth;
    
    /// @dev USDC代币地址（作为中间代币）
    address public immutable usdc;

    /// @dev Uniswap V3 Quoter合约接口
    IUniswapV3Quoter public immutable uniswapV3Quoter;

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化报价合约
     * @param uniswapV3Quoter_ Uniswap V3 Quoter合约地址
     * @param weth_ WETH代币地址
     * @param usdc_ USDC代币地址
     */
    constructor(address uniswapV3Quoter_, address weth_, address usdc_) {
        uniswapV3Quoter = IUniswapV3Quoter(uniswapV3Quoter_);
        weth = weth_;
        usdc = usdc_;
        // 初始化支持的手续费等级：0.01%, 0.05%, 0.3%, 1%
        fees = [100, 500, 3000, 10000];
    }

    // ==================== 外部函数 ====================

    /**
     * @dev 计算用指定代币投资ETF所需的数量和交换路径
     * @param etf ETF合约地址
     * @param srcToken 源代币地址（用户要使用的代币）
     * @param mintAmount 要铸造的ETF数量
     * @return srcAmount 需要的源代币总数量
     * @return swapPaths 每个成分代币对应的交换路径数组
     */
    function quoteInvestWithToken(
        address etf,
        address srcToken,
        uint256 mintAmount
    )
        external
        view
        override
        returns (uint256 srcAmount, bytes[] memory swapPaths)
    {
        // 获取ETF的成分代币信息
        address[] memory tokens = IETFv1(etf).getTokens();
        uint256[] memory tokenAmounts = IETFv1(etf).getInvestTokenAmounts(
            mintAmount
        );

        // 初始化交换路径数组
        swapPaths = new bytes[](tokens.length);
        
        // 遍历每个成分代币，计算所需的源代币数量
        for (uint256 i = 0; i < tokens.length; i++) {
            if (srcToken == tokens[i]) {
                // 如果源代币就是成分代币，直接累加数量
                srcAmount += tokenAmounts[i];
                // 创建同一代币的虚拟路径
                swapPaths[i] = bytes.concat(
                    bytes20(srcToken),
                    bytes3(fees[0]),
                    bytes20(srcToken)
                );
            } else {
                // 需要交换：计算从源代币到成分代币的最优路径
                (bytes memory path, uint256 amountIn) = quoteExactOut(
                    srcToken,
                    tokens[i],
                    tokenAmounts[i]
                );
                srcAmount += amountIn;
                swapPaths[i] = path;
            }
        }
    }

    /**
     * @dev 计算赎回ETF后换成指定代币的数量和交换路径
     * @param etf ETF合约地址
     * @param dstToken 目标代币地址（用户想要获得的代币）
     * @param burnAmount 要销毁的ETF数量
     * @return dstAmount 可获得的目标代币总数量
     * @return swapPaths 每个成分代币对应的交换路径数组
     */
    function quoteRedeemToToken(
        address etf,
        address dstToken,
        uint256 burnAmount
    )
        external
        view
        override
        returns (uint256 dstAmount, bytes[] memory swapPaths)
    {
        // 获取ETF赎回时可得到的成分代币信息
        address[] memory tokens = IETFv1(etf).getTokens();
        uint256[] memory tokenAmounts = IETFv1(etf).getRedeemTokenAmounts(
            burnAmount
        );

        // 初始化交换路径数组
        swapPaths = new bytes[](tokens.length);
        
        // 遍历每个成分代币，计算能换得的目标代币数量
        for (uint256 i = 0; i < tokens.length; i++) {
            if (dstToken == tokens[i]) {
                // 如果目标代币就是成分代币，直接累加数量
                dstAmount += tokenAmounts[i];
                // 创建同一代币的虚拟路径
                swapPaths[i] = bytes.concat(
                    bytes20(dstToken),
                    bytes3(fees[0]),
                    bytes20(dstToken)
                );
            } else {
                // 需要交换：计算从成分代币到目标代币的最优路径
                (bytes memory path, uint256 amountOut) = quoteExactIn(
                    tokens[i],
                    dstToken,
                    tokenAmounts[i]
                );
                dstAmount += amountOut;
                swapPaths[i] = path;
            }
        }
    }

    // ==================== 公共函数 ====================

    /**
     * @dev 精确输出报价：给定输出数量，计算所需输入数量
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param amountOut 期望的输出数量
     * @return path 最优交换路径
     * @return amountIn 需要的输入数量
     */
    function quoteExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) public view returns (bytes memory path, uint256 amountIn) {
        // 获取所有可能的交换路径
        bytes[] memory allPaths = getAllPaths(tokenOut, tokenIn);
        
        // 遍历所有路径，找到成本最低的（输入数量最少的）
        for (uint256 i = 0; i < allPaths.length; i++) {
            try
                uniswapV3Quoter.quoteExactOutput(allPaths[i], amountOut)
            returns (
                uint256 amountIn_,
                uint160[] memory,
                uint32[] memory,
                uint256
            ) {
                // 选择需要输入最少的路径
                if (amountIn_ > 0 && (amountIn == 0 || amountIn_ < amountIn)) {
                    amountIn = amountIn_;
                    path = allPaths[i];
                }
            } catch {
                // 忽略失败的报价尝试
            }
        }
    }

    /**
     * @dev 精确输入报价：给定输入数量，计算可获得的输出数量
     * @param tokenIn 输入代币地址
     * @param tokenOut 输出代币地址
     * @param amountIn 输入数量
     * @return path 最优交换路径
     * @return amountOut 可获得的输出数量
     */
    function quoteExactIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (bytes memory path, uint256 amountOut) {
        // 获取所有可能的交换路径
        bytes[] memory allPaths = getAllPaths(tokenIn, tokenOut);
        
        // 遍历所有路径，找到收益最高的（输出数量最多的）
        for (uint256 i = 0; i < allPaths.length; i++) {
            try uniswapV3Quoter.quoteExactInput(allPaths[i], amountIn) returns (
                uint256 amountOut_,
                uint160[] memory,
                uint32[] memory,
                uint256
            ) {
                // 选择输出最多的路径
                if (amountOut_ > amountOut) {
                    amountOut = amountOut_;
                    path = allPaths[i];
                }
            } catch {
                // 忽略失败的报价尝试
            }
        }
    }

    /**
     * @dev 获取两个代币之间所有可能的交换路径
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @return paths 所有可能的交换路径数组
     */
    function getAllPaths(
        address tokenA,
        address tokenB
    ) public view returns (bytes[] memory paths) {
        // 计算路径总数：直接路径 + 通过中间代币的路径
        // 直接路径：4种费率 = 4条路径
        // 中间代币路径：2个中间代币 * 4种费率 * 4种费率 = 32条路径
        uint totalPaths = fees.length + (fees.length * fees.length * 2);
        paths = new bytes[](totalPaths);

        uint256 index = 0;

        // 1. 生成直接路径：tokenA -> fee -> tokenB
        for (uint256 i = 0; i < fees.length; i++) {
            paths[index] = bytes.concat(
                bytes20(tokenA),
                bytes3(fees[i]),
                bytes20(tokenB)
            );
            index++;
        }

        // 2. 生成通过中间代币的路径：tokenA -> fee1 -> intermediary -> fee2 -> tokenB
        address[2] memory intermediaries = [weth, usdc];
        for (uint256 i = 0; i < intermediaries.length; i++) {
            for (uint256 j = 0; j < fees.length; j++) {
                for (uint256 k = 0; k < fees.length; k++) {
                    paths[index] = bytes.concat(
                        bytes20(tokenA),
                        bytes3(fees[j]),
                        bytes20(intermediaries[i]),
                        bytes3(fees[k]),
                        bytes20(tokenB)
                    );
                    index++;
                }
            }
        }
    }
}