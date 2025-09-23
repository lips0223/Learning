// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IETFv3} from "./IETFv3.sol";

/**
 * @title IETFv4 接口
 * @dev ETFv4合约接口，在ETFv3基础上添加流动性挖矿奖励机制
 */
interface IETFv4 is IETFv3 {
    
    // ==================== 错误定义 ====================
    
    /// @dev 没有可领取的奖励错误
    error NothingClaimable();

    // ==================== 事件定义 ====================
    
    /// @dev 用户挖矿指数更新事件
    /// @param supplier 用户地址
    /// @param deltaIndex 指数增量
    /// @param lastIndex 最新全局指数
    event SupplierIndexUpdated(
        address indexed supplier,
        uint256 deltaIndex,
        uint256 lastIndex
    );
    
    /// @dev 奖励领取事件
    /// @param supplier 用户地址
    /// @param claimedAmount 领取的奖励数量
    event RewardClaimed(address indexed supplier, uint256 claimedAmount);

    // ==================== 外部函数 ====================

    /**
     * @dev 更新挖矿速度（仅管理员）
     * @param speed 每秒产生的奖励代币数量
     */
    function updateMiningSpeedPerSecond(uint256 speed) external;

    /**
     * @dev 提取挖矿代币（仅管理员）
     * @param to 接收地址
     * @param amount 提取数量
     */
    function withdrawMiningToken(address to, uint256 amount) external;

    /**
     * @dev 领取挖矿奖励
     * @notice 用户调用此函数领取累积的挖矿奖励
     */
    function claimReward() external;

    // ==================== 视图函数 ====================

    /**
     * @dev 获取挖矿奖励代币地址
     * @return 挖矿奖励代币合约地址
     */
    function miningToken() external view returns (address);

    /**
     * @dev 获取指数精度常量
     * @return 指数计算的精度基数（1e36）
     */
    function INDEX_SCALE() external view returns (uint256);

    /**
     * @dev 获取每秒挖矿速度
     * @return 每秒产生的奖励代币数量
     */
    function miningSpeedPerSecond() external view returns (uint256);

    /**
     * @dev 获取全局挖矿指数
     * @return 当前全局挖矿指数
     */
    function miningLastIndex() external view returns (uint256);

    /**
     * @dev 获取最后指数更新时间
     * @return 最后一次更新全局指数的时间戳
     */
    function lastIndexUpdateTime() external view returns (uint256);

    /**
     * @dev 获取用户的挖矿指数
     * @param supplier 用户地址
     * @return 用户的挖矿指数
     */
    function supplierLastIndex(
        address supplier
    ) external view returns (uint256);

    /**
     * @dev 获取用户累积的奖励
     * @param supplier 用户地址
     * @return 用户累积但未领取的奖励数量
     */
    function supplierRewardAccrued(
        address supplier
    ) external view returns (uint256);

    /**
     * @dev 获取用户可领取的奖励总数
     * @param supplier 用户地址
     * @return 用户当前可领取的奖励数量（包括实时计算的收益）
     */
    function getClaimableReward(
        address supplier
    ) external view returns (uint256);
}