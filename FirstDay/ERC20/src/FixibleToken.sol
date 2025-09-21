// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
//FixibleToken 合约 继承 ERC20,ERC20Burnable,AccessControl,ERC20Permit,ERC20Votes
contract FixibleToken is
    ERC20,
    ERC20Burnable,
    AccessControl,
    ERC20Permit,
    ERC20Votes
{
    //bytes32 是 Solidity 中的一个数据类型 表示固定大小为32字节的字节数组
    //keccak256 是 Solidity 中的一个内置函数 用于计算输入数据的 Keccak-256 哈希值
    //MINTER_ROLE 角色 用于代币铸造权限管理
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); //定义 MINTER_ROLE 角色 用于代币铸造权限管理
    uint256 public constant INIT_TOTAL_SUPPLY = 1_000_000_000e18; // 1 billion

    constructor(
        address defaultAdmin,
        address minter
    ) ERC20("FixibleToken", "FTK") ERC20Permit("FixibleToken") {
        _mint(defaultAdmin, INIT_TOTAL_SUPPLY); //铸造初始总供应量 给默认管理员地址
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin); //授予默认管理员角色 给指定地址
        _grantRole(MINTER_ROLE, minter); //授予铸造角色 给指定地址
    }

    //mint函数 用于代币铸造
    //address to 代币接收地址 amount 铸造数量
    //onlyRole(MINTER_ROLE) 是 AccessControl 合约提供的修饰符 仅允许具有 MINTER_ROLE 角色的地址调用该函数
    //public 表示该函数可以被合约内外部访问
    // _mint 函数 是 ERC20 合约提供的内部函数 用于铸造新的代币
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // _update 函数 用于更新代币的转移信息
    //override 关键字 表示该函数重写了父合约中的同名函数
    //internal 表示该函数只能在合约内部或继承合约中调用
    //ERC20,ERC20Votes 指定了重写的父合约
    //super 关键字 调用ERC20 和 ERC20Votes 合约中的 _update 函数
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    //nonces 函数 用于返回指定地址的Nonces 验签
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
