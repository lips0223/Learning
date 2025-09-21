// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.24;
//导入 OpenZeppelin 提供的可升级合约库
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

//定义 UpgradeableToken 合约 继承 Initializable,ERC20Upgradeable,ERC20BurnableUpgradeable,AccessControlUpgradeable,ERC20PermitUpgradeable,ERC20VotesUpgradeable,UUPSUpgradeable
contract UUPSupgradeableToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    //同代理升级合约
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //同代理升级合约
    constructor() {
        _disableInitializers();
    }

    //同代理升级合约
    function initialize(
        address defaultAdmin,
        address minter,
        address upgrader
    ) public initializer {
        __ERC20_init("UUPSUpgradeableToken", "UUAT");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ERC20Permit_init("UUPSUpgradeableToken");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    //同代理升级合约
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    //_authorizeUpgrade函数是 UUPSUpgradeable 合约提供的函数 用于授权升级操作
    //override 关键字 表示该函数重写了父合约中的同名函数
    //internal 表示该函数只能在合约内部或继承合约中调用
    //onlyRole(UPGRADER_ROLE) 是 AccessControl 合约提供的修饰符 仅允许具有 UPGRADER_ROLE 角色的地址调用该函数
    // function _authorizeUpgrade(address newImplementation) internal override {
    //     super._update(newImplementation);
    // }  这是错误的写法 ❌

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        // 这里不需要调用任何函数，只需要确认调用者有UPGRADER_ROLE权限即可
    }

    //同代理升级合约
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._update(from, to, value);
    }

    //同代理升级合约
    function nonces(
        address owner
    )
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
