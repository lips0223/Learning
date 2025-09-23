// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入相关接口和库
import {IETFv1} from "../../interfaces/IETFv1.sol";      // ETFv1 合约接口标准
import {FullMath} from "../../libraries/FullMath.sol";   // 高精度数学运算库，防止溢出
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";           // ERC20 代币标准接口
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";             // ERC20 代币标准实现
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // 安全的 ERC20 操作库
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";              // 所有权管理合约

/**
 * @title ETFv1 - 第一版 ETF 合约
 * @dev 实现基础的 ETF 功能：投资、赎回、费用管理
 * @notice 这是一个去中心化的 ETF 产品，用户可以投资一篮子代币并获得 ETF 份额
 */
contract ETFv1 is IETFv1, ERC20, Ownable {
    using SafeERC20 for IERC20;  // 为 IERC20 类型启用 SafeERC20 库的安全操作
    using FullMath for uint256;  // 为 uint256 类型启用高精度数学运算

    // ============== 常量定义 ==============
    uint24 public constant HUNDRED_PERCENT = 1000000; // 100% = 1,000,000 (支持到万分之一的精度)

    // ============== 状态变量 ==============
    address public feeTo;           // 费用接收地址
    uint24 public investFee;        // 投资费用 (万分之几，例如 10000 = 1%)
    uint24 public redeemFee;        // 赎回费用 (万分之几)
    uint256 public minMintAmount;   // 最小铸造金额，防止粉尘攻击

    address[] private _tokens;                        // ETF 包含的代币地址列表
    uint256[] private _initTokenAmountPerShares;      // 每个 ETF 份额对应的初始代币数量（首次投资时使用）

    /**
     * @dev 构造函数 - 初始化 ETF 合约
     * @param name_ ETF 代币名称
     * @param symbol_ ETF 代币符号
     * @param tokens_ ETF 包含的代币地址数组
     * @param initTokenAmountPerShares_ 每个代币对应的初始投资金额数组
     * @param minMintAmount_ 最小铸造金额
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShares_, 
        uint256 minMintAmount_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _tokens = tokens_;
        _initTokenAmountPerShares = initTokenAmountPerShares_;
        minMintAmount = minMintAmount_;
    }

    // ============== 管理员功能 ==============
    
    /**
     * @dev 设置投资和赎回费用 (仅管理员)
     * @param feeTo_ 费用接收地址
     * @param investFee_ 投资费用 (万分之几)
     * @param redeemFee_ 赎回费用 (万分之几)
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
     * @dev 更新最小铸造金额 (仅管理员)
     * @param newMinMintAmount 新的最小铸造金额
     */
    function updateMinMintAmount(uint256 newMinMintAmount) external onlyOwner {
        emit MinMintAmountUpdated(minMintAmount, newMinMintAmount);
        minMintAmount = newMinMintAmount;
    }

    // ============== 核心功能 ==============

    /**
     * @dev 投资函数 - 用户投入代币获得 ETF 份额
     * @param to 接收 ETF 份额的地址
     * @param mintAmount 要铸造的 ETF 份额数量
     * @notice 调用前用户需要先授权所有相关代币给本合约
     */
    function invest(address to, uint256 mintAmount) public {
        // 计算需要投入的各种代币数量
        uint256[] memory tokenAmounts = _invest(to, mintAmount);
        
        // 逐个转入用户的代币到合约
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (tokenAmounts[i] > 0) {
                IERC20(_tokens[i]).safeTransferFrom(
                    msg.sender,      // 从调用者
                    address(this),   // 转入到合约
                    tokenAmounts[i]  // 转入数量
                );
            }
        }
    }

    /**
     * @dev 赎回函数 - 用户销毁 ETF 份额获得对应代币
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的 ETF 份额数量
     */
    function redeem(address to, uint256 burnAmount) public {
        _redeem(to, burnAmount);
    }

    // ============== 查询功能 ==============

    /**
     * @dev 获取 ETF 包含的所有代币地址
     * @return 代币地址数组
     */
    function getTokens() public view returns (address[] memory) {
        return _tokens;
    }

    /**
     * @dev 获取每个代币的初始投资金额比例
     * @return 初始金额数组
     */
    function getInitTokenAmountPerShares()
        public
        view
        returns (uint256[] memory)
    {
        return _initTokenAmountPerShares;
    }

    /**
     * @dev 计算投资指定 ETF 份额需要的各代币数量
     * @param mintAmount 要铸造的 ETF 份额数量
     * @return tokenAmounts 需要投入的各代币数量数组
     */
    function getInvestTokenAmounts(
        uint256 mintAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply = totalSupply();  // 当前 ETF 总供应量
        tokenAmounts = new uint256[](_tokens.length);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (totalSupply > 0) {
                // 如果 ETF 已有供应量，按比例计算
                uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
                // 公式: tokenAmount / tokenReserve = mintAmount / totalSupply
                tokenAmounts[i] = tokenReserve.mulDivRoundingUp(
                    mintAmount,
                    totalSupply
                );
            } else {
                // 首次投资，使用初始比例
                tokenAmounts[i] = mintAmount.mulDivRoundingUp(
                    _initTokenAmountPerShares[i],
                    1e18  // 假设 ETF 精度为 18 位
                );
            }
        }
    }

    /**
     * @dev 计算赎回指定 ETF 份额能获得的各代币数量
     * @param burnAmount 要销毁的 ETF 份额数量
     * @return tokenAmounts 能获得的各代币数量数组
     */
    function getRedeemTokenAmounts(
        uint256 burnAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        // 扣除赎回费用
        if (redeemFee > 0) {
            uint256 fee = (burnAmount * redeemFee) / HUNDRED_PERCENT;
            burnAmount -= fee;
        }

        uint256 totalSupply = totalSupply();
        tokenAmounts = new uint256[](_tokens.length);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
            // 公式: tokenAmount / tokenReserve = burnAmount / totalSupply
            tokenAmounts[i] = tokenReserve.mulDiv(burnAmount, totalSupply);
        }
    }

    // ============== 内部功能 ==============

    /**
     * @dev 内部投资逻辑
     * @param to 接收 ETF 份额的地址
     * @param mintAmount 要铸造的数量
     * @return tokenAmounts 需要的各代币数量
     */
    function _invest(
        address to,
        uint256 mintAmount
    ) internal returns (uint256[] memory tokenAmounts) {
        // 检查最小铸造数量
        if (mintAmount < minMintAmount) revert LessThanMinMintAmount();
        
        // 计算需要的代币数量
        tokenAmounts = getInvestTokenAmounts(mintAmount);
        
        uint256 fee;
        if (investFee > 0) {
            // 计算并收取投资费用
            fee = (mintAmount * investFee) / HUNDRED_PERCENT;
            _mint(feeTo, fee);                    // 费用给费用接收地址
            _mint(to, mintAmount - fee);          // 剩余份额给投资者
        } else {
            _mint(to, mintAmount);                // 无费用时全部给投资者
        }

        emit Invested(to, mintAmount, fee, tokenAmounts);
    }

    /**
     * @dev 内部赎回逻辑
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的 ETF 份额数量
     * @return tokenAmounts 返还的各代币数量
     */
    function _redeem(
        address to,
        uint256 burnAmount
    ) internal returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply = totalSupply();
        tokenAmounts = new uint256[](_tokens.length);
        
        // 先销毁用户的 ETF 份额
        _burn(msg.sender, burnAmount);

        uint256 fee;
        if (redeemFee > 0) {
            // 计算并收取赎回费用
            fee = (burnAmount * redeemFee) / HUNDRED_PERCENT;
            _mint(feeTo, fee);  // 将费用以 ETF 形式给费用接收地址
        }

        // 实际用于赎回的数量（扣除费用后）
        uint256 actuallyBurnAmount = burnAmount - fee;
        
        // 按比例返还各种代币
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
            tokenAmounts[i] = tokenReserve.mulDiv(
                actuallyBurnAmount,
                totalSupply
            );
            // 转出代币给用户（如果目标地址不是合约自身）
            if (to != address(this) && tokenAmounts[i] > 0)
                IERC20(_tokens[i]).safeTransfer(to, tokenAmounts[i]);
        }

        emit Redeemed(msg.sender, to, burnAmount, fee, tokenAmounts);
    }

    // ============== 预留功能（v3版本使用） ==============

    /**
     * @dev 添加新代币到 ETF（内部函数，v3 版本使用）
     * @param token 要添加的代币地址
     * @return index 代币在数组中的索引
     */
    function _addToken(address token) internal returns (uint256 index) {
        // 检查代币是否已存在
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) revert TokenExists();
        }
        index = _tokens.length;
        _tokens.push(token);
        emit TokenAdded(token, index);
    }

    /**
     * @dev 从 ETF 中移除代币（内部函数，v3 版本使用）
     * @param token 要移除的代币地址
     * @return index 被移除代币原来的索引
     */
    function _removeToken(address token) internal returns (uint256 index) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) {
                index = i;
                // 将最后一个元素移到当前位置，然后删除最后一个
                _tokens[i] = _tokens[_tokens.length - 1];
                _tokens.pop();
                emit TokenRemoved(token, index);
                return index;
            }
        }
        revert TokenNotFound();
    }
}