// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AggregatorV3Interface
 * @dev Chainlink价格预言机标准接口
 * 用于获取实时代币价格数据，支持ETFv3的动态再平衡功能
 */
interface AggregatorV3Interface {
    
    /**
     * @dev 获取价格数据的小数位数
     * @return 小数位数（例如：8表示价格精度为8位小数）
     */
    function decimals() external view returns (uint8);

    /**
     * @dev 获取价格预言机的描述信息
     * @return 描述字符串（例如："ETH / USD"）
     */
    function description() external view returns (string memory);

    /**
     * @dev 获取价格预言机版本号
     * @return 版本号
     */
    function version() external view returns (uint256);

    /**
     * @dev 获取指定轮次的价格数据
     * @param _roundId 轮次ID
     * @return roundId 实际轮次ID
     * @return answer 价格答案（按decimals()返回的精度）
     * @return startedAt 轮次开始时间
     * @return updatedAt 最后更新时间
     * @return answeredInRound 回答轮次
     */
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /**
     * @dev 获取最新轮次的价格数据
     * @return roundId 最新轮次ID
     * @return answer 最新价格（按decimals()返回的精度）
     * @return startedAt 轮次开始时间
     * @return updatedAt 最后更新时间
     * @return answeredInRound 回答轮次
     * @notice 这是ETFv3再平衡功能的核心数据源
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}