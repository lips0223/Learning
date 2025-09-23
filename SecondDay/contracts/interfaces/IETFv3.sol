// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IETFv2} from "./IETFv2.sol";

/**
 * @title IETFv3 接口
 * @dev ETFv3合约接口，在ETFv2基础上添加动态再平衡和价格预言机功能
 */
interface IETFv3 is IETFv2 {
    
    // ==================== 错误定义 ====================
    
    /// @dev 数组长度不匹配错误
    error DifferentArrayLength();
    
    /// @dev 尚未到再平衡时间错误
    error NotRebalanceTime();
    
    /// @dev 代币权重总和不等于100%错误
    error InvalidTotalWeights();
    
    /// @dev 操作被禁止错误（如移除仍有余额的代币）
    error Forbidden();
    
    /// @dev 未找到价格预言机错误
    /// @param token 代币地址
    error PriceFeedNotFound(address token);

    // ==================== 事件定义 ====================
    
    /// @dev 再平衡完成事件
    /// @param reservesBefore 再平衡前各代币余额
    /// @param reservesAfter 再平衡后各代币余额
    event Rebalanced(uint256[] reservesBefore, uint256[] reservesAfter);

    // ==================== 外部函数 ====================

    /**
     * @dev 执行ETF再平衡操作
     * @notice 根据目标权重和当前市值差异，自动调整各代币持仓比例
     */
    function rebalance() external;

    /**
     * @dev 设置代币价格预言机
     * @param tokens 代币地址数组
     * @param priceFeeds 对应的Chainlink价格预言机地址数组
     */
    function setPriceFeeds(
        address[] memory tokens,
        address[] memory priceFeeds
    ) external;

    /**
     * @dev 设置代币目标权重
     * @param tokens 代币地址数组
     * @param targetWeights 对应的目标权重数组（基点表示，10000=100%）
     */
    function setTokenTargetWeights(
        address[] memory tokens,
        uint24[] memory targetWeights
    ) external;

    /**
     * @dev 更新再平衡时间间隔
     * @param newInterval 新的时间间隔（秒）
     */
    function updateRebalanceInterval(uint256 newInterval) external;

    /**
     * @dev 更新再平衡偏差阈值
     * @param newDeviance 新的偏差阈值（基点表示）
     */
    function updateRebalanceDeviance(uint24 newDeviance) external;

    /**
     * @dev 添加新的成分代币
     * @param token 要添加的代币地址
     */
    function addToken(address token) external;

    /**
     * @dev 移除成分代币
     * @param token 要移除的代币地址
     * @notice 只能移除余额为0且权重为0的代币
     */
    function removeToken(address token) external;

    // ==================== 视图函数 ====================

    /**
     * @dev 获取上次再平衡时间
     * @return 上次再平衡的时间戳
     */
    function lastRebalanceTime() external view returns (uint256);

    /**
     * @dev 获取再平衡时间间隔
     * @return 再平衡时间间隔（秒）
     */
    function rebalanceInterval() external view returns (uint256);

    /**
     * @dev 获取再平衡偏差阈值
     * @return 偏差阈值（基点表示）
     */
    function rebalanceDeviance() external view returns (uint24);

    /**
     * @dev 获取代币的价格预言机地址
     * @param token 代币地址
     * @return priceFeed 价格预言机地址
     */
    function getPriceFeed(
        address token
    ) external view returns (address priceFeed);

    /**
     * @dev 获取代币的目标权重
     * @param token 代币地址
     * @return targetWeight 目标权重（基点表示）
     */
    function getTokenTargetWeight(
        address token
    ) external view returns (uint24 targetWeight);

    /**
     * @dev 获取各代币的市场价值信息
     * @return tokens 代币地址数组
     * @return tokenPrices 代币价格数组（来自价格预言机）
     * @return tokenMarketValues 代币市值数组（价格 × 持仓量）
     * @return totalValues ETF总市值
     */
    function getTokenMarketValues()
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory tokenPrices,
            uint256[] memory tokenMarketValues,
            uint256 totalValues
        );
}