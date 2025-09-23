// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入基础合约
import {ETFv2} from "../ETFv2/ETFv2.sol";
// 导入接口
import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";
// 导入库
import {FullMath} from "../../libraries/FullMath.sol";
// 导入OpenZeppelin合约
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ETFv3 Lite - 轻量级动态再平衡ETF合约
 * @dev 在ETFv2基础上增加基础再平衡功能
 */
contract ETFv3Lite is ETFv2 {
    using FullMath for uint256;

    // ==================== 状态变量 ====================
    
    /// @dev 上次再平衡时间
    uint256 public lastRebalanceTime;
    
    /// @dev 再平衡时间间隔（秒）
    uint256 public rebalanceInterval;
    
    /// @dev 代币地址 => Chainlink价格预言机地址
    mapping(address token => address priceFeed) public getPriceFeed;
    
    /// @dev 代币地址 => 目标权重（基点，10000=100%）
    mapping(address token => uint24 targetWeight) public getTokenTargetWeight;

    // ==================== 事件 ====================
    
    event Rebalanced(uint256 timestamp);
    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event TargetWeightUpdated(address indexed token, uint24 targetWeight);

    // ==================== 构造函数 ====================

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        uint256 rebalanceInterval_
    ) ETFv2(name_, symbol_, tokens_, initTokenAmountPerShare_, minMintAmount_, swapRouter_, weth_) {
        rebalanceInterval = rebalanceInterval_;
        lastRebalanceTime = block.timestamp;
        
        // 设置默认等权重
        uint24 defaultWeight = uint24(10000 / tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            getTokenTargetWeight[tokens_[i]] = defaultWeight;
        }
    }

    // ==================== 管理员功能 ====================

    /**
     * @dev 设置价格预言机
     */
    function setPriceFeed(address token, address priceFeed) external onlyOwner {
        getPriceFeed[token] = priceFeed;
        emit PriceFeedUpdated(token, priceFeed);
    }

    /**
     * @dev 设置目标权重
     */
    function setTargetWeight(address token, uint24 targetWeight) external onlyOwner {
        require(targetWeight <= 10000, "Weight too high");
        getTokenTargetWeight[token] = targetWeight;
        emit TargetWeightUpdated(token, targetWeight);
    }

    /**
     * @dev 设置再平衡间隔
     */
    function setRebalanceInterval(uint256 interval) external onlyOwner {
        rebalanceInterval = interval;
    }

    // ==================== 只读功能 ====================

    /**
     * @dev 获取代币价格（美元价格，8位小数）
     */
    function getTokenPrice(address token) public view returns (uint256) {
        address priceFeed = getPriceFeed[token];
        if (priceFeed == address(0)) return 0;
        
        (, int256 price, , ,) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(price > 0, "Invalid price");
        
        return uint256(price);
    }

    /**
     * @dev 检查是否需要再平衡
     */
    function needsRebalance() public view returns (bool) {
        return block.timestamp >= lastRebalanceTime + rebalanceInterval;
    }

    // ==================== 再平衡功能 ====================

    /**
     * @dev 手动触发再平衡
     */
    function rebalance() external {
        require(needsRebalance(), "Too early to rebalance");
        _executeRebalance();
    }

    /**
     * @dev 执行再平衡逻辑（简化版）
     */
    function _executeRebalance() internal {
        lastRebalanceTime = block.timestamp;
        emit Rebalanced(block.timestamp);
    }
}