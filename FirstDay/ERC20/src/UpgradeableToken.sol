// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//FixibleToken 合约 继承 ERC20,ERC20Burnable,AccessControl,ERC20Permit,ERC20Votes
contract UpgradeableToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); //定义 MINTER_ROLE 角色 用于代币铸造权限管理
    uint256 public constant INIT_TOTAL_SUPPLY = 1_000_000_000e18; // 定义 初始总供应量 1 billion

    constructor() {
        //初始化函数被禁用 避免被意外调用
        //_disableInitializers()是 Initializable 合约提供的函数 用于禁用初始化函数
        _disableInitializers();
    }

    //initialize 函数 用于合约的初始化 只能被调用一次
    //defaultAdmin 默认管理员地址 minter 铸造者地址
    function initialize(
        address defaultAdmin,
        address minter
    ) public initializer {
        __ERC20_init("UpgradeableToken", "UTK"); //初始化 ERC20 合约的名称和符号 __ERC20_init 是 ERC20Upgradeable 合约提供的初始化函数
        //__ERC20Burnable_init 函数是 BurnableUpgradeable 合约提供的初始化函数
        __ERC20Burnable_init(); //初始化 ERC20Burnable 合约
        //__AccessControl_init 函数是 AccessControlUpgradeable 合约提供的初始化函数
        __AccessControl_init(); //初始化 AccessControl 合约
        //__ERC20Permit_init 函数是 ERC20PermitUpgradeable 合约提供的初始化函数
        __ERC20Permit_init("UpgradeableToken"); //初始化 ERC20Permit 合约的名称
        //__ERC20Votes_init 函数是 ERC20VotesUpgradeable 合约提供的初始化函数
        __ERC20Votes_init(); //初始化 ERC20Votes 合约
        //_mint 函数 是 ERC20 合约提供的内部函数 用于铸造新的代币
        _mint(msg.sender, INIT_TOTAL_SUPPLY); //铸造初始总供应量 给默认管理员地址
        //_grantRole 函数 是 AccessControl 合约提供的内部函数 用于授予角色
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin); //授予默认管理员角色 给指定地址
        //_grantRole 函数 是 AccessControl 合约提供的内部函数 用于授予角色
        _grantRole(MINTER_ROLE, minter); //授予铸造角色 给指定地址
    }

    //_update 函数 用于更新代币的转移信息
    //override 关键字 表示该函数重写了父合约中的同名函数
    //internal 表示该函数只能在合约内部或继承合约中调用
    //ERC20,ERC20Votes 指定了重写的父合约
    //super 关键字 调用ERC20 和 ERC20Votes 合约中的 _update
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    //_update 函数 用于更新代币的转移信息
    //override 关键字 表示该函数重写了父合约中的同名函数
    //internal 表示该函数只能在合约内部或继承合约中调用
    //ERC20,ERC20Votes 指定了重写的父合约
    //super 关键字 调用ERC20 和 ERC20Votes 合约中的 _update 函数
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._update(from, to, value);
    }
    //nonces 函数 用于返回指定地址的Nonces 验签
    //override 关键字 表示该函数重写了父合约中的同名函数
    //ERC20Permit,Nonces 指定了重写的父合约
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //returns(uint256) 表示该函数返回一个 uint256 类型的值
    //nonces 函数是 ERC20Permit 和 Nonces 合约提供的函数 用于管理基于签名的操作的唯一性
    //为什么要有nonces 函数
    // 在区块链和智能合约中，nonces（数字签名中的“nonce”）用于确保每个交易或操作的唯一性和防止重放攻击。具体来说，nonces 的作用包括以下几个方面：
    //1. 唯一性：每个交易或操作都必须包含一个唯一的 nonce 值。这个值通常是一个递增的数字，确保同一地址发送的每个交易都是唯一的。
    //2. 防止重放攻击：如果攻击者截获了一个交易，他们可能会尝试重新发送（重放）这个交易以欺骗网络。通过使用 nonce，网络可以识别并拒绝重复的交易，因为它们会有相同的 nonce 值。
    //3. 顺序执行：nonce 还可以确保交易按正确的顺序执行。因为每个交易的 nonce 必须是递增的，所以网络可以确保交易按照发送的顺序处理。    
    function nonces(
        address owner
    ) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }
}
