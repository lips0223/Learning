// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入基础合约
import {ETFv3} from "../ETFv3/ETFv3.sol";
// 导入接口
import {IETFv4} from "../../interfaces/IETFv4.sol";
// 导入OpenZeppelin合约
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// 导入库
import {FullMath} from "../../libraries/FullMath.sol";

/**
 * @title ETFv4 流动性挖矿ETF合约
 * @dev 在ETFv3基础上增加了流动性挖矿奖励机制
 * 
 * 核心功能：
 * 1. 继承ETFv3的所有功能（动态再平衡、价格预言机等）
 * 2. 流动性挖矿：为ETF持有者提供额外的代币奖励
 * 3. 奖励分配：基于持仓比例和时间的线性奖励机制
 * 4. 实时计算：支持实时查询和领取累积奖励
 */
contract ETFv4 is IETFv4, ETFv3 {
    using SafeERC20 for IERC20;
    using FullMath for uint256;

    // ==================== 常量定义 ====================
    
    /// @dev 指数精度常量（1e36），用于高精度奖励计算
    uint256 public constant INDEX_SCALE = 1e36;

    // ==================== 状态变量 ====================
    
    /// @dev 挖矿奖励代币地址
    address public miningToken;
    
    /// @dev 每秒产生的奖励代币数量
    uint256 public miningSpeedPerSecond;
    
    /// @dev 全局挖矿指数
    uint256 public miningLastIndex;
    
    /// @dev 最后指数更新时间
    uint256 public lastIndexUpdateTime;

    /// @dev 用户地址 => 用户挖矿指数
    mapping(address => uint256) public supplierLastIndex;
    
    /// @dev 用户地址 => 累积奖励数量
    mapping(address => uint256) public supplierRewardAccrued;

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化ETFv4合约
     * @param name_ ETF代币名称
     * @param symbol_ ETF代币符号
     * @param tokens_ 初始成分代币地址数组
     * @param initTokenAmountPerShare_ 每份ETF对应的成分代币初始数量
     * @param minMintAmount_ 最小铸造数量
     * @param swapRouter_ Uniswap V3交换路由地址
     * @param weth_ WETH代币地址
     * @param etfQuoter_ ETF报价合约地址
     * @param miningToken_ 挖矿奖励代币地址
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        address etfQuoter_,
        address miningToken_
    )
        ETFv3(
            name_,
            symbol_,
            tokens_,
            initTokenAmountPerShare_,
            minMintAmount_,
            swapRouter_,
            weth_,
            etfQuoter_
        )
    {
        miningToken = miningToken_;
        miningLastIndex = INDEX_SCALE; // 初始化为1e36
    }

    // ==================== 管理员函数 ====================

    /**
     * @dev 更新挖矿速度（仅管理员）
     * @param speed 每秒产生的奖励代币数量
     */
    function updateMiningSpeedPerSecond(uint256 speed) external onlyOwner {
        _updateMiningIndex();
        miningSpeedPerSecond = speed;
    }

    /**
     * @dev 提取挖矿代币（仅管理员）
     * @param to 接收地址
     * @param amount 提取数量
     */
    function withdrawMiningToken(
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(miningToken).safeTransfer(to, amount);
    }

    // ==================== 用户函数 ====================

    /**
     * @dev 领取挖矿奖励
     * @notice 用户调用此函数领取累积的挖矿奖励
     */
    function claimReward() external {
        _updateMiningIndex();
        _updateSupplierIndex(msg.sender);

        uint256 claimable = supplierRewardAccrued[msg.sender];
        if (claimable == 0) revert NothingClaimable();

        supplierRewardAccrued[msg.sender] = 0;
        IERC20(miningToken).safeTransfer(msg.sender, claimable);
        emit RewardClaimed(msg.sender, claimable);
    }

    // ==================== 视图函数 ====================

    /**
     * @dev 获取用户可领取的奖励总数
     * @param supplier 用户地址
     * @return 用户当前可领取的奖励数量（包括实时计算的收益）
     */
    function getClaimableReward(
        address supplier
    ) external view returns (uint256) {
        uint256 claimable = supplierRewardAccrued[supplier];

        // 计算最新的全局指数
        uint256 globalLastIndex = miningLastIndex;
        uint256 totalSupply_ = totalSupply();
        uint256 deltaTime = block.timestamp - lastIndexUpdateTime;
        
        if (totalSupply_ > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {
            uint256 deltaReward = miningSpeedPerSecond * deltaTime;
            uint256 deltaIndex = deltaReward.mulDiv(INDEX_SCALE, totalSupply_);
            globalLastIndex += deltaIndex;
        }

        // 计算用户可累加的奖励
        uint256 supplierIndex = supplierLastIndex[supplier];
        uint256 supplierSupply = balanceOf(supplier);
        
        if (supplierIndex > 0 && supplierSupply > 0) {
            uint256 supplierDeltaIndex = globalLastIndex - supplierIndex;
            uint256 supplierDeltaReward = supplierSupply.mulDiv(
                supplierDeltaIndex,
                INDEX_SCALE
            );
            claimable += supplierDeltaReward;
        }

        return claimable;
    }

    // ==================== 内部函数 ====================

    /**
     * @dev 更新全局挖矿指数
     * @notice 根据时间经过和总供应量计算新的全局指数
     */
    function _updateMiningIndex() internal {
        if (miningLastIndex == 0) {
            // 首次初始化
            miningLastIndex = INDEX_SCALE;
            lastIndexUpdateTime = block.timestamp;
        } else {
            uint256 totalSupply_ = totalSupply();
            uint256 deltaTime = block.timestamp - lastIndexUpdateTime;
            
            if (totalSupply_ > 0 && deltaTime > 0 && miningSpeedPerSecond > 0) {
                // 计算新增奖励和指数增量
                uint256 deltaReward = miningSpeedPerSecond * deltaTime;
                uint256 deltaIndex = deltaReward.mulDiv(
                    INDEX_SCALE,
                    totalSupply_
                );
                miningLastIndex += deltaIndex;
                lastIndexUpdateTime = block.timestamp;
            } else if (deltaTime > 0) {
                // 只更新时间，不更新指数
                lastIndexUpdateTime = block.timestamp;
            }
        }
    }

    /**
     * @dev 更新用户挖矿指数
     * @param supplier 用户地址
     * @notice 计算用户自上次更新以来累积的奖励
     */
    function _updateSupplierIndex(address supplier) internal {
        uint256 lastIndex = supplierLastIndex[supplier];
        uint256 supply = balanceOf(supplier);
        uint256 deltaIndex;
        
        if (lastIndex > 0 && supply > 0) {
            // 计算指数差值和对应的奖励
            deltaIndex = miningLastIndex - lastIndex;
            uint256 deltaReward = supply.mulDiv(deltaIndex, INDEX_SCALE);
            supplierRewardAccrued[supplier] += deltaReward;
        }
        
        // 更新用户指数
        supplierLastIndex[supplier] = miningLastIndex;
        emit SupplierIndexUpdated(supplier, deltaIndex, miningLastIndex);
    }

    // ==================== 重写函数 ====================

    /**
     * @dev 重写ERC20的_update函数
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转账数量
     * @notice 在每次代币转移时更新挖矿指数，确保奖励计算的准确性
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        // 更新全局挖矿指数
        _updateMiningIndex();
        
        // 更新发送方和接收方的挖矿指数
        if (from != address(0)) _updateSupplierIndex(from);
        if (to != address(0)) _updateSupplierIndex(to);
        
        // 执行代币转移
        super._update(from, to, value);
    }
}