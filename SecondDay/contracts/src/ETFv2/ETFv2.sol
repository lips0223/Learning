// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入基础ETFv1合约
import {ETFv1} from "../ETFv1/ETFv1.sol";
// 导入ETFv2接口
import {IETFv2} from "../../interfaces/IETFv2.sol";
// 导入WETH接口
import {IWETH} from "../../interfaces/IWETH.sol";
// 导入路径处理库
import {Path} from "../../libraries/Path.sol";
// 导入OpenZeppelin安全ERC20库
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 导入Uniswap V3交换路由接口
import {IV3SwapRouter} from "../../interfaces/IV3SwapRouter.sol";

/**
 * @title ETFv2 增强版ETF合约
 * @dev 继承ETFv1的基础功能，增加了ETH投资和任意代币交换功能
 * 支持通过Uniswap V3进行代币交换，实现更灵活的投资和赎回方式
 */
contract ETFv2 is IETFv2, ETFv1 {
    using SafeERC20 for IERC20;
    using Path for bytes;

    // ==================== 状态变量 ====================
    
    /// @dev Uniswap V3交换路由合约地址
    address public immutable swapRouter;
    
    /// @dev WETH代币地址，用于ETH和ERC20代币之间的转换
    address public immutable weth;

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化ETFv2合约
     * @param name_ ETF代币名称
     * @param symbol_ ETF代币符号
     * @param tokens_ 成分代币地址数组
     * @param initTokenAmountPerShare_ 每份ETF对应的成分代币初始数量
     * @param minMintAmount_ 最小铸造数量
     * @param swapRouter_ Uniswap V3交换路由地址
     * @param weth_ WETH代币地址
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_
    ) ETFv1(name_, symbol_, tokens_, initTokenAmountPerShare_, minMintAmount_) {
        swapRouter = swapRouter_;
        weth = weth_;
    }

    /// @dev 接收ETH的回调函数
    receive() external payable {}

    // ==================== 投资功能 ====================

    /**
     * @dev 使用ETH投资ETF
     * @param to 接收ETF代币的地址
     * @param mintAmount 要铸造的ETF数量
     * @param swapPaths 从WETH到各成分代币的交换路径数组
     */
    function investWithETH(
        address to,
        uint256 mintAmount,
        bytes[] memory swapPaths
    ) external payable {
        address[] memory tokens = getTokens(); //getTokens是ETFv1的函数 用于获取成分代币地址数组
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();
        uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);

        // 将ETH转换为WETH
        uint256 maxETHAmount = msg.value;
        IWETH(weth).deposit{value: maxETHAmount}();
        _approveToSwapRouter(weth);

        uint256 totalPaid;
        // 遍历所有成分代币，执行必要的交换
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            //_checkSwapPath是内部函数 用于验证Uniswap V3的交换路径是否合法
            if (!_checkSwapPath(tokens[i], weth, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == weth) {
                // 如果成分代币就是WETH，直接使用
                totalPaid += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换获得所需的成分代币
                totalPaid += IV3SwapRouter(swapRouter).exactOutput(
                    IV3SwapRouter.ExactOutputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountOut: tokenAmounts[i],
                        amountInMaximum: type(uint256).max
                    })
                );
            }
        }

        // 退还多余的ETH
        uint256 leftAfterPaid = maxETHAmount - totalPaid;
        IWETH(weth).withdraw(leftAfterPaid);
        payable(msg.sender).transfer(leftAfterPaid);

        // 执行ETF投资
        _invest(to, mintAmount);

        emit InvestedWithETH(to, mintAmount, totalPaid);
    }

    /**
     * @dev 使用指定代币投资ETF
     * @param srcToken 源代币地址
     * @param to 接收ETF代币的地址
     * @param mintAmount 要铸造的ETF数量
     * @param maxSrcTokenAmount 最大源代币消耗量
     * @param swapPaths 从源代币到各成分代币的交换路径数组
     */
    function investWithToken(
        address srcToken,
        address to,
        uint256 mintAmount,
        uint256 maxSrcTokenAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();
        //getInvestTokenAmounts是ETFv1的函数 用于计算投资指定数量ETF所需的各成分代币数量
        uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);

        // 转入源代币
        IERC20(srcToken).safeTransferFrom(
            msg.sender,
            address(this),
            maxSrcTokenAmount
        );
        _approveToSwapRouter(srcToken);

        uint256 totalPaid;
        // 遍历所有成分代币，执行必要的交换
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], srcToken, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == srcToken) {
                // 如果成分代币就是源代币，直接使用
                totalPaid += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换获得所需的成分代币
                totalPaid += IV3SwapRouter(swapRouter).exactOutput(
                    IV3SwapRouter.ExactOutputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountOut: tokenAmounts[i],
                        amountInMaximum: type(uint256).max
                    })
                );
            }
        }

        // 退还多余的源代币
        uint256 leftAfterPaid = maxSrcTokenAmount - totalPaid;
        IERC20(srcToken).safeTransfer(msg.sender, leftAfterPaid);

        // 执行ETF投资
        _invest(to, mintAmount);

        emit InvestedWithToken(srcToken, to, mintAmount, totalPaid);
    }

    // ==================== 赎回功能 ====================

    /**
     * @dev 赎回ETF并换取ETH
     * @param to 接收ETH的地址
     * @param burnAmount 要销毁的ETF数量
     * @param minETHAmount 最小接收ETH数量（滑点保护）
     * @param swapPaths 从各成分代币到WETH的交换路径数组
     */
    function redeemToETH(
        address to,
        uint256 burnAmount,
        uint256 minETHAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();

        // 执行ETF赎回，获得成分代币
        uint256[] memory tokenAmounts = _redeem(address(this), burnAmount);

        uint256 totalReceived;
        // 将所有成分代币交换为WETH
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], weth, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == weth) {
                // 如果成分代币就是WETH，直接累加
                totalReceived += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换为WETH
                _approveToSwapRouter(tokens[i]);
                totalReceived += IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: tokenAmounts[i],
                        amountOutMinimum: 1
                    })
                );
            }
        }

        // 检查滑点保护
        if (totalReceived < minETHAmount) revert OverSlippage();
        
        // 将WETH转换为ETH并发送
        IWETH(weth).withdraw(totalReceived);
        _safeTransferETH(to, totalReceived);

        emit RedeemedToETH(to, burnAmount, totalReceived);
    }

    /**
     * @dev 赎回ETF并换取指定代币
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的ETF数量
     * @param minDstTokenAmount 最小接收目标代币数量（滑点保护）
     * @param swapPaths 从各成分代币到目标代币的交换路径数组
     */
    function redeemToToken(
        address dstToken,
        address to,
        uint256 burnAmount,
        uint256 minDstTokenAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();

        // 执行ETF赎回，获得成分代币
        uint256[] memory tokenAmounts = _redeem(address(this), burnAmount);

        uint256 totalReceived;
        // 将所有成分代币交换为目标代币
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], dstToken, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == dstToken) {
                // 如果成分代币就是目标代币，直接转账
                IERC20(tokens[i]).safeTransfer(to, tokenAmounts[i]);
                totalReceived += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换为目标代币
                _approveToSwapRouter(tokens[i]);
                totalReceived += IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: swapPaths[i],
                        recipient: to,
                        deadline: block.timestamp + 300,
                        amountIn: tokenAmounts[i],
                        amountOutMinimum: 1
                    })
                );
            }
        }

        // 检查滑点保护
        if (totalReceived < minDstTokenAmount) revert OverSlippage();

        emit RedeemedToToken(dstToken, to, burnAmount, totalReceived);
    }

    // ==================== 内部辅助函数 ====================

    /**
     * @dev 为Uniswap路由合约授权代币
     * @param token 要授权的代币地址
     */
    function _approveToSwapRouter(address token) internal {
        if (
            IERC20(token).allowance(address(this), swapRouter) <
            type(uint256).max
        ) {
            IERC20(token).forceApprove(swapRouter, type(uint256).max);
        }
    }

    /**
     * @dev 检查交换路径的有效性
     * @param tokenA 起始代币
     * @param tokenB 结束代币  
     * @param path 交换路径
     * @return 路径是否有效
     */
    function _checkSwapPath(
        address tokenA,
        address tokenB,
        bytes memory path
    ) internal pure returns (bool) {
        (address firstToken, address secondToken, ) = path.decodeFirstPool();
        
        if (tokenA == tokenB) {
            // 同一代币的情况：路径应该是tokenA -> fee -> tokenA且没有多个池子
            if (
                firstToken == tokenA &&
                secondToken == tokenA &&
                !path.hasMultiplePools()
            ) {
                return true;
            } else {
                return false;
            }
        } else {
            // 不同代币的情况：检查路径的起始和结束代币
            if (firstToken != tokenA) return false;
            
            // 跳到路径的最后一个池子
            while (path.hasMultiplePools()) {
                path = path.skipToken();
            }
            (, secondToken, ) = path.decodeFirstPool();
            if (secondToken != tokenB) return false;
            return true;
        }
    }

    /**
     * @dev 安全转账ETH
     * @param to 接收地址
     * @param value 转账金额
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert SafeTransferETHFailed();
    }
}