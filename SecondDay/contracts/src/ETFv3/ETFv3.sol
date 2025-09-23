// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入基础合约
import {ETFv2} from "../ETFv2/ETFv2.sol";
// 导入接口
import {IETFv3} from "../../interfaces/IETFv3.sol";
import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";
import {IETFQuoter} from "../../interfaces/IETFQuoter.sol";
// 导入库
import {FullMath} from "../../libraries/FullMath.sol";
// 导入OpenZeppelin合约
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IV3SwapRouter} from "../../interfaces/IV3SwapRouter.sol";

/**
 * @title ETFv3 动态再平衡ETF合约
 * @dev 在ETFv2基础上增加了自动再平衡功能和Chainlink价格预言机集成
 * 
 * 核心功能：
 * 1. 动态代币管理：可添加/移除成分代币
 * 2. 自动再平衡：根据目标权重和市场价格自动调整持仓
 * 3. 价格预言机：集成Chainlink获取实时价格数据
 * 4. 权重管理：支持设置和调整各代币的目标权重
 */
contract ETFv3 is IETFv3, ETFv2 {
    using FullMath for uint256;

    // ==================== 状态变量 ====================
    
    /// @dev ETF报价合约地址，用于获取最优交换路径
    address public etfQuoter;

    /// @dev 上次再平衡时间
    uint256 public lastRebalanceTime;
    
    /// @dev 再平衡时间间隔（秒）
    uint256 public rebalanceInterval;
    
    /// @dev 再平衡偏差阈值（基点，10000=100%）
    uint24 public rebalanceDeviance;

    /// @dev 代币地址 => Chainlink价格预言机地址
    mapping(address token => address priceFeed) public getPriceFeed;
    
    /// @dev 代币地址 => 目标权重（基点，10000=100%）
    mapping(address token => uint24 targetWeight) public getTokenTargetWeight;

    // ==================== 修饰符 ====================
    
    /**
     * @dev 检查所有代币的目标权重总和是否等于100%
     */
    modifier _checkTotalWeights() {
        address[] memory tokens = getTokens();
        uint24 totalWeights;
        for (uint256 i = 0; i < tokens.length; i++) {
            totalWeights += getTokenTargetWeight[tokens[i]];
        }
        if (totalWeights != HUNDRED_PERCENT) revert InvalidTotalWeights();
        _;
    }

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化ETFv3合约
     * @param name_ ETF代币名称
     * @param symbol_ ETF代币符号
     * @param tokens_ 初始成分代币地址数组
     * @param initTokenAmountPerShare_ 每份ETF对应的成分代币初始数量
     * @param minMintAmount_ 最小铸造数量
     * @param swapRouter_ Uniswap V3交换路由地址
     * @param weth_ WETH代币地址
     * @param etfQuoter_ ETF报价合约地址
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        address etfQuoter_
    )
        ETFv2(
            name_,
            symbol_,
            tokens_,
            initTokenAmountPerShare_,
            minMintAmount_,
            swapRouter_,
            weth_
        )
    {
        etfQuoter = etfQuoter_;
    }

    // ==================== 管理员函数 ====================

    /**
     * @dev 设置代币价格预言机（仅管理员）
     * @param tokens 代币地址数组
     * @param priceFeeds 对应的Chainlink价格预言机地址数组
     */
    function setPriceFeeds(
        address[] memory tokens,
        address[] memory priceFeeds
    ) external onlyOwner {
        if (tokens.length != priceFeeds.length) revert DifferentArrayLength();
        for (uint256 i = 0; i < tokens.length; i++) {
            getPriceFeed[tokens[i]] = priceFeeds[i];
        }
    }

    /**
     * @dev 设置代币目标权重（仅管理员）
     * @param tokens 代币地址数组
     * @param targetWeights 对应的目标权重数组（基点表示）
     */
    function setTokenTargetWeights(
        address[] memory tokens,
        uint24[] memory targetWeights
    ) external onlyOwner {
        if (tokens.length != targetWeights.length) revert InvalidArrayLength();
        for (uint256 i = 0; i < targetWeights.length; i++) {
            getTokenTargetWeight[tokens[i]] = targetWeights[i];
        }
    }

    /**
     * @dev 更新再平衡时间间隔（仅管理员）
     * @param newInterval 新的时间间隔（秒）
     */
    function updateRebalanceInterval(uint256 newInterval) external onlyOwner {
        rebalanceInterval = newInterval;
    }

    /**
     * @dev 更新再平衡偏差阈值（仅管理员）
     * @param newDeviance 新的偏差阈值（基点表示）
     */
    function updateRebalanceDeviance(uint24 newDeviance) external onlyOwner {
        rebalanceDeviance = newDeviance;
    }

    /**
     * @dev 添加新的成分代币（仅管理员）
     * @param token 要添加的代币地址
     */
    function addToken(address token) external onlyOwner {
        _addToken(token);
    }

    /**
     * @dev 移除成分代币（仅管理员）
     * @param token 要移除的代币地址
     * @notice 只能移除余额为0且权重为0的代币
     */
    function removeToken(address token) external onlyOwner {
        if (
            IERC20(token).balanceOf(address(this)) > 0 ||
            getTokenTargetWeight[token] > 0
        ) revert Forbidden();
        _removeToken(token);
    }

    // ==================== 再平衡功能 ====================

    /**
     * @dev 执行ETF再平衡操作
     * @notice 根据目标权重和当前市值差异，自动调整各代币持仓比例
     */
    function rebalance() external _checkTotalWeights {
        // 检查是否到了允许再平衡的时间
        if (block.timestamp < lastRebalanceTime + rebalanceInterval)
            revert NotRebalanceTime();
        lastRebalanceTime = block.timestamp;

        // 计算每个代币的市值和总市值
        (
            address[] memory tokens,
            int256[] memory tokenPrices,
            uint256[] memory tokenMarketValues,
            uint256 totalValues
        ) = getTokenMarketValues();

        // 计算每个代币需要再平衡进行交换的数量
        int256[] memory tokenSwapableAmounts = new int256[](tokens.length);
        uint256[] memory reservesBefore = new uint256[](tokens.length);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            reservesBefore[i] = IERC20(tokens[i]).balanceOf(address(this));

            if (getTokenTargetWeight[tokens[i]] == 0) continue;

            // 计算目标市值
            uint256 weightedValue = (totalValues *
                getTokenTargetWeight[tokens[i]]) / HUNDRED_PERCENT;
            
            // 计算允许的偏差范围
            uint256 lowerValue = (weightedValue *
                (HUNDRED_PERCENT - rebalanceDeviance)) / HUNDRED_PERCENT;
            uint256 upperValue = (weightedValue *
                (HUNDRED_PERCENT + rebalanceDeviance)) / HUNDRED_PERCENT;
            
            // 如果当前市值超出允许范围，计算需要调整的数量
            if (
                tokenMarketValues[i] < lowerValue ||
                tokenMarketValues[i] > upperValue
            ) {
                int256 deltaValue = int256(weightedValue) -
                    int256(tokenMarketValues[i]);
                uint8 tokenDecimals = IERC20Metadata(tokens[i]).decimals();

                if (deltaValue > 0) {
                    // 需要买入更多该代币
                    tokenSwapableAmounts[i] = int256(
                        uint256(deltaValue).mulDiv(
                            10 ** tokenDecimals,
                            uint256(tokenPrices[i])
                        )
                    );
                } else {
                    // 需要卖出部分该代币
                    tokenSwapableAmounts[i] = -int256(
                        uint256(-deltaValue).mulDiv(
                            10 ** tokenDecimals,
                            uint256(tokenPrices[i])
                        )
                    );
                }
            }
        }

        // 执行代币交换
        _swapTokens(tokens, tokenSwapableAmounts);

        // 记录再平衡后的余额
        uint256[] memory reservesAfter = new uint256[](tokens.length);
        for (uint256 i = 0; i < reservesAfter.length; i++) {
            reservesAfter[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        emit Rebalanced(reservesBefore, reservesAfter);
    }

    // ==================== 视图函数 ====================

    /**
     * @dev 获取各代币的市场价值信息
     * @return tokens 代币地址数组
     * @return tokenPrices 代币价格数组（来自Chainlink预言机）
     * @return tokenMarketValues 代币市值数组（价格 × 持仓量）
     * @return totalValues ETF总市值
     */
    function getTokenMarketValues()
        public
        view
        returns (
            address[] memory tokens,
            int256[] memory tokenPrices,
            uint256[] memory tokenMarketValues,
            uint256 totalValues
        )
    {
        tokens = getTokens();
        uint256 length = tokens.length;
        tokenPrices = new int256[](length);
        tokenMarketValues = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            // 获取价格预言机
            AggregatorV3Interface priceFeed = AggregatorV3Interface(
                getPriceFeed[tokens[i]]
            );
            if (address(priceFeed) == address(0))
                revert PriceFeedNotFound(tokens[i]);
            
            // 获取最新价格
            (, tokenPrices[i], , , ) = priceFeed.latestRoundData();

            // 计算市值 = 持仓量 × 价格
            uint8 tokenDecimals = IERC20Metadata(tokens[i]).decimals();
            uint256 reserve = IERC20(tokens[i]).balanceOf(address(this));
            tokenMarketValues[i] = reserve.mulDiv(
                uint256(tokenPrices[i]),
                10 ** tokenDecimals
            );
            totalValues += tokenMarketValues[i];
        }
    }

    // ==================== 内部函数 ====================

    /**
     * @dev 执行代币交换以实现再平衡
     * @param tokens 代币地址数组
     * @param tokenSwapableAmounts 需要交换的数量数组（正数买入，负数卖出）
     */
    function _swapTokens(
        address[] memory tokens,
        int256[] memory tokenSwapableAmounts
    ) internal {
        address usdc = IETFQuoter(etfQuoter).usdc();
        
        // 第一步：执行所有卖出操作，获得USDC余额
        uint256 usdcRemaining = _sellTokens(usdc, tokens, tokenSwapableAmounts);
        
        // 第二步：执行所有买入操作
        usdcRemaining = _buyTokens(
            usdc,
            tokens,
            tokenSwapableAmounts,
            usdcRemaining
        );
        
        // 第三步：如果仍有USDC余额，按权重比例分配买入
        if (usdcRemaining > 0) {
            uint256 usdcLeft = usdcRemaining;
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 amountIn = (usdcRemaining *
                    getTokenTargetWeight[tokens[i]]) / HUNDRED_PERCENT;
                if (amountIn == 0) continue;
                if (amountIn > usdcLeft) {
                    amountIn = usdcLeft;
                }
                
                // 获取交换路径并执行
                (bytes memory path, ) = IETFQuoter(etfQuoter).quoteExactIn(
                    usdc,
                    tokens[i],
                    amountIn
                );
                IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: path,
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: amountIn,
                        amountOutMinimum: 1
                    })
                );
                usdcLeft -= amountIn;
                if (usdcLeft == 0) break;
            }
        }
    }

    /**
     * @dev 执行卖出操作，将代币换成USDC
     * @param usdc USDC代币地址
     * @param tokens 代币地址数组
     * @param tokenSwapableAmounts 交换数量数组
     * @return usdcRemaining 获得的USDC数量
     */
    function _sellTokens(
        address usdc,
        address[] memory tokens,
        int256[] memory tokenSwapableAmounts
    ) internal returns (uint256 usdcRemaining) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenSwapableAmounts[i] < 0) {
                uint256 amountIn = uint256(-tokenSwapableAmounts[i]);
                
                // 获取最优交换路径
                (bytes memory path, ) = IETFQuoter(etfQuoter).quoteExactIn(
                    tokens[i],
                    usdc,
                    amountIn
                );
                
                // 授权并执行交换
                _approveToSwapRouter(tokens[i]);
                usdcRemaining += IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: path,
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: amountIn,
                        amountOutMinimum: 1
                    })
                );
            }
        }
    }

    /**
     * @dev 执行买入操作，用USDC换取代币
     * @param usdc USDC代币地址
     * @param tokens 代币地址数组
     * @param tokenSwapableAmounts 交换数量数组
     * @param usdcRemaining 可用的USDC数量
     * @return usdcLeft 剩余的USDC数量
     */
    function _buyTokens(
        address usdc,
        address[] memory tokens,
        int256[] memory tokenSwapableAmounts,
        uint256 usdcRemaining
    ) internal returns (uint256 usdcLeft) {
        usdcLeft = usdcRemaining;
        _approveToSwapRouter(usdc);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenSwapableAmounts[i] > 0) {
                // 计算精确输出所需的USDC数量
                (bytes memory path, uint256 amountIn) = IETFQuoter(etfQuoter)
                    .quoteExactOut(
                        usdc,
                        tokens[i],
                        uint256(tokenSwapableAmounts[i])
                    );
                
                if (usdcLeft >= amountIn) {
                    // 有足够USDC，执行精确输出交换
                    usdcLeft -= IV3SwapRouter(swapRouter).exactOutput(
                        IV3SwapRouter.ExactOutputParams({
                            path: path,
                            recipient: address(this),
                            deadline: block.timestamp + 300,
                            amountOut: uint256(tokenSwapableAmounts[i]),
                            amountInMaximum: type(uint256).max
                        })
                    );
                } else if (usdcLeft > 0) {
                    // USDC不足，执行精确输入交换
                    (path, ) = IETFQuoter(etfQuoter).quoteExactIn(
                        usdc,
                        tokens[i],
                        usdcLeft
                    );
                    IV3SwapRouter(swapRouter).exactInput(
                        IV3SwapRouter.ExactInputParams({
                            path: path,
                            recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: usdcLeft,
                            amountOutMinimum: 1
                        })
                    );
                    usdcLeft = 0;
                    break;
                }
            }
        }
    }
}