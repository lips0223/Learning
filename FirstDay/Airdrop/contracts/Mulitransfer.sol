// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//定义 MultiTransfer 合约 继承 Ownable  
contract MultiTransfer is Ownable {
    //using xxx for yyy; 语法 用于将库函数绑定到特定类型    
    using SafeERC20 for IERC20; //using 关键字 用于引入库函数 使 IERC20 类型的变量可以调用 SafeERC20 库中的函数
    address public immutable token; //定义一个 immutable 类型的地址变量 token 用于存储代币合约地址 不可变

    error DifferentArrayLength(); //错误处理 当收件人数组和金额数组长度不同时抛出该错误

    //初始化构造函数 接受一个地址参数 token_ 用于设置代币合约地址
    //Ownable(msg.sender) 调用父合约 Ownable 的构造函数 将合约拥有者设置为部署者地址
    constructor(address token_) Ownable(msg.sender) {
        token = token_;
    }
    //batchTransfer 函数 用于批量转账
    //address[] calldata recipients 收件人地址数组 uint256[] calldata amounts 转账金额数组
    //onlyOwner 是 Ownable 合约提供的修饰符 仅允许合约拥有者调用该函数
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //calldata 表示该数组存储在调用数据中 只能用于外部函数参数 不能被修改
    //revert 关键字 用于抛出异常 并回滚交易
    //if 语句 检查收件人数组和金额数组长度是否相等 如果不等则抛出 DifferentArrayLength 错误
    //for 循环 遍历收件人数组和金额数组
    //IERC20(token).safeTransfer(recipients[i], amounts[i]); 调用 SafeERC20 库中的 safeTransfer 函数 将指定金额的代币转账给指定收件人
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (recipients.length != amounts.length) revert DifferentArrayLength();
        for (uint i = 0; i < recipients.length; i++) {
            IERC20(token).safeTransfer(recipients[i], amounts[i]);
        }
    }
}