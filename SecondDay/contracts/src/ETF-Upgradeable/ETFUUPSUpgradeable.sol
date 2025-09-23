// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入接口
import {IETFv1} from "../../interfaces/IETFv1.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";
import {IETFQuoter} from "../../interfaces/IETFQuoter.sol";
import {IV3SwapRouter} from "../../interfaces/IV3SwapRouter.sol";
// 导入库
import {FullMath} from "../../libraries/FullMath.sol";
import {Path} from "../../libraries/Path.sol";
// 导入OpenZeppelin可升级合约
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ETFUUPSUpgradeable 可升级ETF合约
 * @dev 使用UUPS代理模式实现的可升级ETF合约，集成所有ETF功能
 * 
 * 核心功能：
 * 1. 可升级架构：使用UUPS代理模式，支持合约逻辑升级
 * 2. 完整ETF功能：投资、赎回、费用管理、动态再平衡
 * 3. 流动性挖矿：为持有者提供额外代币奖励
 * 4. 价格预言机：集成Chainlink获取实时价格
 * 5. 初始化机制：支持代理合约初始化参数设置
 */
contract ETFUUPSUpgradeable is
    IETFv1,
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;
    using FullMath for uint256;
    using Path for bytes;

    // ==================== 错误定义 ====================
    
    error InvalidTotalWeights();
    error DifferentArrayLength();
    error InvalidArrayLength();
    error Forbidden();

    // ==================== 常量定义 ====================
    
    /// @dev 百分比基数（100% = 1,000,000基点）
    uint24 public constant HUNDRED_PERCENT = 1000000;
    
    /// @dev 指数精度常量（1e36），用于高精度挖矿计算
    uint256 public constant INDEX_SCALE = 1e36;

    // ==================== 状态变量 ====================
    
    /// @dev 费用接收地址
    address public feeTo;
    
    /// @dev 投资费用（基点）
    uint24 public investFee;
    
    /// @dev 赎回费用（基点）
    uint24 public redeemFee;
    
    /// @dev 最小铸造数量
    uint256 public minMintAmount;

    /// @dev Uniswap V3交换路由地址
    address public swapRouter;
    
    /// @dev WETH代币地址
    address public weth;
    
    /// @dev ETF报价合约地址
    address public etfQuoter;

    /// @dev 上次再平衡时间
    uint256 public lastRebalanceTime;
    
    /// @dev 再平衡时间间隔
    uint256 public rebalanceInterval;
    
    /// @dev 再平衡偏差阈值
    uint24 public rebalanceDeviance;

    /// @dev 挖矿奖励代币地址
    address public miningToken;
    
    /// @dev 每秒挖矿速度
    uint256 public miningSpeedPerSecond;
    
    /// @dev 全局挖矿指数
    uint256 public miningLastIndex;
    
    /// @dev 最后指数更新时间
    uint256 public lastIndexUpdateTime;

    // ==================== 映射存储 ====================
    
    /// @dev 代币地址 => 价格预言机地址
    mapping(address => address) public getPriceFeed;
    
    /// @dev 代币地址 => 目标权重
    mapping(address => uint24) public getTokenTargetWeight;
    
    /// @dev 用户地址 => 挖矿指数
    mapping(address => uint256) public supplierLastIndex;
    
    /// @dev 用户地址 => 累积奖励
    mapping(address => uint256) public supplierRewardAccrued;

    // ==================== 私有存储 ====================
    
    /// @dev 成分代币地址数组
    address[] private _tokens;
    
    /// @dev 每份ETF对应的代币初始数量
    uint256[] private _initTokenAmountPerShares;

    // ==================== 修饰符 ====================
    
    /**
     * @dev 检查总权重是否等于100%
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
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev 接收ETH的回调函数
    receive() external payable {}

    // ==================== 初始化结构 ====================
    
    /**
     * @dev 初始化参数结构
     */
    struct InitializeParams {
        address owner;              // 合约拥有者
        string name;               // ETF代币名称
        string symbol;             // ETF代币符号
        address[] tokens;          // 成分代币地址数组
        uint256[] initTokenAmountPerShares; // 每份ETF对应的代币数量
        uint256 minMintAmount;     // 最小铸造数量
        address swapRouter;        // Uniswap交换路由
        address weth;             // WETH地址
        address etfQuoter;        // ETF报价合约
        address miningToken;      // 挖矿奖励代币
    }

    // ==================== 初始化函数 ====================
    
    /**
     * @dev 初始化函数（代理合约部署后调用）
     * @param params 初始化参数结构
     */
    function initialize(InitializeParams memory params) public initializer {
        __ERC20_init(params.name, params.symbol);
        __Ownable_init(params.owner);
        __UUPSUpgradeable_init();

        _tokens = params.tokens;
        _initTokenAmountPerShares = params.initTokenAmountPerShares;
        minMintAmount = params.minMintAmount;
        swapRouter = params.swapRouter;
        weth = params.weth;
        etfQuoter = params.etfQuoter;
        miningToken = params.miningToken;
        miningLastIndex = INDEX_SCALE;
    }

    // ==================== 管理员函数 ====================
    
    /**
     * @dev 设置费用参数（仅管理员）
     * @param feeTo_ 费用接收地址
     * @param investFee_ 投资费用（基点）
     * @param redeemFee_ 赎回费用（基点）
     */
    function setFee(
        address feeTo_,
        uint24 investFee_,
        uint24 redeemFee_
    ) external onlyOwner {
        feeTo = feeTo_;
        investFee = investFee_;
        redeemFee = redeemFee_;
    }

    /**
     * @dev 更新最小铸造数量（仅管理员）
     * @param newMinMintAmount 新的最小铸造数量
     */
    function updateMinMintAmount(uint256 newMinMintAmount) external onlyOwner {
        emit MinMintAmountUpdated(minMintAmount, newMinMintAmount);
        minMintAmount = newMinMintAmount;
    }

    /**
     * @dev 设置价格预言机（仅管理员）
     * @param tokens 代币地址数组
     * @param priceFeeds 价格预言机地址数组
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
     * @param targetWeights 目标权重数组
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
     * @dev 更新再平衡间隔（仅管理员）
     * @param newInterval 新的时间间隔
     */
    function updateRebalanceInterval(uint256 newInterval) external onlyOwner {
        rebalanceInterval = newInterval;
    }

    /**
     * @dev 更新再平衡偏差（仅管理员）
     * @param newDeviance 新的偏差阈值
     */
    function updateRebalanceDeviance(uint24 newDeviance) external onlyOwner {
        rebalanceDeviance = newDeviance;
    }

    /**
     * @dev 添加成分代币（仅管理员）
     * @param token 代币地址
     */
    function addToken(address token) external onlyOwner {
        _addToken(token);
    }

    /**
     * @dev 获取每份ETF对应的成分代币初始数量
     * @return 每份ETF对应的成分代币数量数组
     */
    function getInitTokenAmountPerShares() external view returns (uint256[] memory) {
        return _initTokenAmountPerShares;
    }

    /**
     * @dev 移除成分代币（仅管理员）
     * @param token 代币地址
     */
    function removeToken(address token) external onlyOwner {
        if (
            IERC20(token).balanceOf(address(this)) > 0 ||
            getTokenTargetWeight[token] > 0
        ) revert Forbidden();
        _removeToken(token);
    }

    // ==================== 视图函数 ====================
    
    /**
     * @dev 获取成分代币数组
     * @return 成分代币地址数组
     */
    function getTokens() public view returns (address[] memory) {
        return _tokens;
    }

    /**
     * @dev 获取投资所需的代币数量
     * @param mintAmount 要铸造的ETF数量
     * @return tokenAmounts 各代币所需数量数组
     */
    function getInvestTokenAmounts(
        uint256 mintAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply_ = totalSupply();
        address[] memory tokens = getTokens();
        tokenAmounts = new uint256[](tokens.length);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (totalSupply_ == 0) {
                tokenAmounts[i] = _initTokenAmountPerShares[i].mulDiv(
                    mintAmount,
                    1e18
                );
            } else {
                tokenAmounts[i] = IERC20(tokens[i])
                    .balanceOf(address(this))
                    .mulDiv(mintAmount, totalSupply_);
            }
        }
    }

    /**
     * @dev 获取赎回可得的代币数量
     * @param burnAmount 要销毁的ETF数量
     * @return tokenAmounts 各代币可得数量数组
     */
    function getRedeemTokenAmounts(
        uint256 burnAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply_ = totalSupply();
        address[] memory tokens = getTokens();
        tokenAmounts = new uint256[](tokens.length);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenAmounts[i] = IERC20(tokens[i])
                .balanceOf(address(this))
                .mulDiv(burnAmount, totalSupply_);
        }
    }

    /**
     * @dev 投资ETF（基础版本）
     * @param to 接收ETF代币的地址
     * @param mintAmount 要铸造的ETF数量
     */
    function invest(address to, uint256 mintAmount) external {
        if (mintAmount < minMintAmount) revert LessThanMinMintAmount();
        
        address[] memory tokens = getTokens();
        uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);
        
        // 转入所需代币
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenAmounts[i]
                );
            }
        }
        
        // 计算费用
        uint256 fee = mintAmount.mulDiv(investFee, HUNDRED_PERCENT);
        uint256 actualMintAmount = mintAmount - fee;
        
        // 铸造ETF代币
        _mint(to, actualMintAmount);
        if (fee > 0 && feeTo != address(0)) {
            _mint(feeTo, fee);
        }
        
        emit Invested(to, actualMintAmount, fee, tokenAmounts);
    }

    /**
     * @dev 赎回ETF（基础版本）
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的ETF数量
     */
    function redeem(address to, uint256 burnAmount) external {
        // 销毁ETF代币
        _burn(msg.sender, burnAmount);
        
        // 计算费用
        uint256 fee = burnAmount.mulDiv(redeemFee, HUNDRED_PERCENT);
        uint256 actualBurnAmount = burnAmount - fee;
        
        address[] memory tokens = getTokens();
        uint256[] memory tokenAmounts = getRedeemTokenAmounts(actualBurnAmount);
        
        // 转出代币
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] > 0) {
                IERC20(tokens[i]).safeTransfer(to, tokenAmounts[i]);
            }
        }
        
        // 处理费用
        if (fee > 0 && feeTo != address(0)) {
            _mint(feeTo, fee);
        }
        
        emit Redeemed(msg.sender, to, actualBurnAmount, fee, tokenAmounts);
    }

    // ==================== 升级相关函数 ====================
    
    /**
     * @dev 授权升级（仅管理员）
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // ==================== 内部函数 ====================
    
    /**
     * @dev 添加代币到ETF中
     * @param token 要添加的代币地址
     */
    function _addToken(address token) internal {
        address[] memory tokens = getTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) revert TokenExists();
        }
        _tokens.push(token);
        _initTokenAmountPerShares.push(0);
        emit TokenAdded(token, _tokens.length - 1);
    }

    /**
     * @dev 从ETF中移除代币
     * @param token 要移除的代币地址
     */
    function _removeToken(address token) internal {
        address[] memory tokens = getTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                _tokens[i] = _tokens[tokens.length - 1];
                _initTokenAmountPerShares[i] = _initTokenAmountPerShares[tokens.length - 1];
                _tokens.pop();
                _initTokenAmountPerShares.pop();
                emit TokenRemoved(token, i);
                return;
            }
        }
        revert TokenNotFound();
    }
}