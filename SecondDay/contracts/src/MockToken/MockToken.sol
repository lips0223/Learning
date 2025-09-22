// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20, Ownable {
    uint8 private _decimals; //定义 _decimals 变量 用于存储代币的小数位数
    // 授权的铸造者地址
    mapping(address => bool) public minters;

    //ERC20(name_, symbol_) 调用父合约 ERC20 的构造函数 初始化名称和符号
    constructor(
        //构造函数 初始化 ERC20 合约的名称和符号 并铸造初始余额
        string memory name_, //name_ 代币名称 symbol_ 代币符号 decimals_ 代币小数位数 initialBalance_ 初始余额
        string memory symbol_, //symbol_ 代币符号
        uint8 decimals_, //decimals_ 代币小数位数
        address owner_
    ) ERC20(name_, symbol_) Ownable(owner_) {
        _decimals = decimals_;
    }

    //modifier onlyMinter 仅允许授权的铸造者调用该函数
    //modifier 关键字 用于定义函数修饰符 和function类似 但不能有函数体 
    //require(minters[msg.sender], "Not minter"); 检查调用者是否是授权的铸造者 如果不是则抛出异常 并显示错误信息 "Not minter"
    //_; 表示函数体 将在修饰符的最后执行    
    modifier onlyMinter() {
        require(minters[msg.sender], "Not minter");
        _;
    }
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
    //重写 mint 函数用于代币铸造
    //address to 代币接收地址 value 铸造数量
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //_mint 函数 是 ERC20 合约提供的内部函数 用于铸造新的代币
    function mint(address to, uint256 value) external onlyMinter{
        _mint(to, value);
    }

    //重写 decimals 函数 用于返回代币的小数位数
    //override 关键字 表示该函数重写了父合约中的同名函数
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //returns(uint8) 表示该函数返回一个无符号整数
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
