// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ETFv2} from "../ETFv2/ETFv2.sol";
import {ETFv1} from "../ETFv1/ETFv1.sol";
import {IETFv1} from "../../interfaces/IETFv1.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ETFv4Lite - 简化版ETFv4合约
 * @dev 移除流动性挖矿等复杂功能，保留核心ETF功能
 */
contract ETFv4Lite is ETFv2 {
    using SafeERC20 for IERC20;
    
    // 协议代币地址
    address public protocolToken;
    
    // 挖矿相关参数（简化版）
    uint256 public rewardRate = 1e18; // 每秒奖励数量
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;
    
    event RewardPaid(address indexed user, uint256 reward);
    event ProtocolTokenSet(address indexed token);
    
    /**
     * @dev 构造函数
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        address protocolToken_
    ) ETFv2(name_, symbol_, tokens_, initTokenAmountPerShare_, minMintAmount_, swapRouter_, weth_) {
        protocolToken = protocolToken_;
    }
    
    /**
     * @dev 设置协议代币地址
     */
    function setProtocolToken(address _protocolToken) external onlyOwner {
        protocolToken = _protocolToken;
        emit ProtocolTokenSet(_protocolToken);
    }
    
    /**
     * @dev 更新用户奖励
     */
    function updateReward(address account) internal {
        if (account != address(0)) {
            uint256 userBalance = balanceOf(account);
            if (userBalance > 0) {
                uint256 timeElapsed = block.timestamp - lastUpdateTime[account];
                if (timeElapsed > 0) {
                    rewards[account] += (userBalance * rewardRate * timeElapsed) / 1e18;
                }
            }
            lastUpdateTime[account] = block.timestamp;
        }
    }
    
    /**
     * @dev 领取奖励
     */
    function claimReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            if (protocolToken != address(0)) {
                IERC20(protocolToken).safeTransfer(msg.sender, reward);
            }
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    /**
     * @dev 投资时更新奖励
     */
    function investWithReward(
        address to,
        uint256 amount
    ) external {
        updateReward(to);
        invest(to, amount);
    }
    
    /**
     * @dev 赎回时更新奖励
     */
    function redeemWithReward(
        address to,
        uint256 amount
    ) external {
        updateReward(msg.sender);
        redeem(to, amount);
    }
    
    /**
     * @dev 查看待领取奖励
     */
    function earned(address account) external view returns (uint256) {
        uint256 userBalance = balanceOf(account);
        if (userBalance == 0) return rewards[account];
        
        uint256 timeElapsed = block.timestamp - lastUpdateTime[account];
        return rewards[account] + (userBalance * rewardRate * timeElapsed) / 1e18;
    }
    
    /**
     * @dev 设置奖励速率（仅所有者）
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }
}