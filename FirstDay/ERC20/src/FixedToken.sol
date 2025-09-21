// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;
//ERC20 标准接口
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//ERC20Votes 扩展合约 用于实现基于投票的治理功能
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
//ERC20Permit 扩展合约 用于实现基于签名的批准功能 Nonces 用于管理基于签名的操作的唯一性
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
//定义 FixedToken 合约 继承 ERC20,ERC20Permit,ERC20Votes
contract FixedToken is ERC20,ERC20Permit,ERC20Votes{
    //构造函数 初始化 ERC20,ERC20Permit 合约的名称和符号 并铸造初始余额
    //ERC20("FixedToken","FTK") 调用父合约 ERC20 的构造函数 初始化名称和符号
    //ERC20Permit("FixedToken") 调用父合约 ERC20Permit 的构造函数 初始化名称
    //_mint(msg.sender,1000000*10**decimals()) 调用 _mint 函数 将初始余额铸造给部署者地址 msg.sender
    //decimals() 函数 返回代币的小数位数 默认为18
    /****
     *  在 Solidity 中，当一个合约继承多个父合约时，构造函数可以通过修饰符链式调用的方式来初始化所有父合约。
     * 例如，在 FixedToken 合约中，构造函数通过 ERC20("FixedToken", "FTK") 和 ERC20Permit("FixedToken") 来初始化两个父合约。
     * 这种方式确保了所有父合约的构造函数都被正确调用，从而避免了钻石继承问题。
     * 这种写法是 Solidity 推荐的方式，可以确保合约的正确初始化和继承关系的清晰。
     */
    //msg.sender 是 Solidity 中的全局变量 表示当前交易的发送者地址
    //1000000*10**decimals() 计算初始铸造的代币数量 这里铸造了 1000000 个代币 考虑到小数位数 需要乘以 10 的 小数位数 次方
    constructor()ERC20("FixedToken","FTK")ERC20Permit("FixedToken"){
        _mint(msg.sender,1000000*10**decimals());
    }
    //update 函数 用于更新代币的转移信息
    //override 关键字 表示该函数重写了父合约中的同名函数
    //internal 表示该函数只能在合约内部或继承合约中调用
    //ERC20,ERC20Votes 指定了重写的父合约
    //super 关键字 调用ERC20 和 ERC20Votes 合约中的 _update 函数    
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20,ERC20Votes){
        super._update(from,to,value);   
    }
    //nonces 函数 用于返回指定地址的Nonces
    //override 关键字 表示该函数重写了父合约中的同名函数
    //ERC20Permit,Nonces 指定了重写的父合约
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //returns(uint256) 表示该函数返回一个 uint256 类型的值
    //nonces 函数是 ERC20Permit 和 Nonces 合约提供的函数 用于管理基于签名的操作的唯一性
    function nonces(address owner) public view override(ERC20Permit,Nonces) returns(uint256){
        return super.nonces(owner);
    }

}
