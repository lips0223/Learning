// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入OpenZeppelin合约
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title ETFProtocolToken ETF协议代币
 * @dev 用于ETFv4流动性挖矿奖励的协议代币
 * 
 * 功能特性：
 * 1. ERC20标准代币功能
 * 2. 代币销毁功能（ERC20Burnable）
 * 3. 基于角色的访问控制（AccessControl）
 * 4. EIP-2612签名许可（ERC20Permit）
 * 5. 治理投票功能（ERC20Votes）
 * 6. 基于时间戳的时钟模式
 */
contract ETFProtocolToken is
    ERC20,
    ERC20Burnable,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    // ==================== 常量定义 ====================
    
    /// @dev 铸造者角色标识
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @dev 初始总供应量：1百万代币
    uint256 public constant INIT_TOTAL_SUPPLY = 1_000_000e18;

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化ETF协议代币
     * @param defaultAdmin 默认管理员地址
     * @param minter 铸造者地址
     */
    constructor(
        address defaultAdmin,
        address minter
    )
        ERC20("BlockETF Protocol Token", "EPT")
        ERC20Permit("BlockETF Protocol Token")
    {
        // 向部署者铸造初始供应量
        _mint(msg.sender, INIT_TOTAL_SUPPLY);
        
        // 设置角色权限
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    // ==================== 外部函数 ====================

    /**
     * @dev 铸造新代币（仅铸造者）
     * @param to 接收地址
     * @param amount 铸造数量
     * @notice 只有具有MINTER_ROLE的地址才能调用此函数
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // ==================== 治理相关函数 ====================

    /**
     * @dev 获取当前时钟值（重写IERC6372）
     * @return 当前区块时间戳
     * @notice 使治理系统基于时间戳而非区块号
     */
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    /**
     * @dev 获取时钟模式（重写IERC6372）
     * @return 时钟模式字符串
     * @notice 表明使用时间戳模式
     */
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // ==================== 重写函数 ====================
    
    /**
     * @dev 重写_update函数以支持多重继承
     * @param from 发送方地址
     * @param to 接收方地址
     * @param value 转账数量
     * @notice Solidity要求的重写函数，用于解决多重继承冲突
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /**
     * @dev 重写nonces函数以支持多重继承
     * @param owner 代币持有者地址
     * @return 当前nonce值
     * @notice Solidity要求的重写函数，用于解决多重继承冲突
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}