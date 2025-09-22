// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockToken} from "../MockToken/MockToken.sol";

contract TokenAirDrop is Ownable {
    using ECDSA for bytes32; //using 关键字 用于引入库函数 使 bytes32 类型的变量可以调用 ECDSA 库中的函数
    using MessageHashUtils for bytes32; //using 关键字 用于引入库函数 使 bytes32 类型的变量可以调用 MessageHashUtils 库中的函数

    address public signer; //定义一个地址变量 signer 用于存储签名者地址
    mapping(uint256 => bool) public nonceUsed; //nonceUsed 映射 用于存储已使用的 Nonce 防止重放攻击
    mapping(address => mapping(address =>uint256)) public userClaimed; // userClaimed 映射 用于存储用户已经领取的空投数量
    
    // 事件定义
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);
    event TokensClaimed(address indexed user, address indexed token, uint256 amount, uint256 nonce);
    //初始化构造函数 接受两个参数 signer_ 签名者地址 owner_ 合约拥有者地址
    //Ownable(owner_) 调用父合约 Ownable 的构造函数 将合约拥有者设置为 owner_ 地址
    //signer = signer_ 将传入的签名者地址赋值给 signer 变量
    constructor(address signer_, address owner_) Ownable(owner_) {
        signer = signer_;
    }

    //updateSigner 函数 用于更新签名者地址
    function updateSigner(address signer_) external onlyOwner {
        address oldSigner = signer;
        signer = signer_;
        emit SignerUpdated(oldSigner, signer_);
    }
    //claim 函数 用于用户领取空投
    function claimTokens (
        address token, //领取的代币地址
        uint256 amount, //领取的代币数量
        uint256 nonce, //防重放攻击的随机数
        uint256 expireAt, //签名过期时间
        bytes calldata signature //签名数据 calldata 关键字 表示该参数存储在调用数据中 只能用于外部函数参数 不能被修改
    ) external {
        require(block.timestamp <= expireAt, "Signature expired"); //使用 require 语句 检查当前时间是否小于等于签名过期时间 如果不满足条件则抛出异常 并显示错误信息 "Signature expired"
        require(!nonceUsed[nonce], "Nonce already used"); //使用 require 语句 检查该 Nonce 是否已被使用 如果已使用则抛出异常 并显示错误信息 "Nonce already used"

        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, token, amount, nonce, expireAt)); //使用 abi.encodePacked 函数 将用户地址 代币地址 领取数量 Nonce 和过期时间 编码为字节数组 并使用 keccak256 函数 计算消息哈希
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash(); //调用 MessageHashUtils 库中的 toEthSignedMessageHash 函数 将消息哈希转换为以太坊签名消息哈希
        address recoveredSigner = ethSignedMessageHash.recover(signature); //调用 ECDSA 库中的 recover 函数 使用签名数据 恢复出签名者地址
        require(recoveredSigner == signer, "Invalid signature"); //使用 require 语句 检查恢复出的签名者地址是否与存储的签名者地址相同 如果不相同则抛出异常 并显示错误信息 "Invalid signature"

        nonceUsed[nonce] = true; //将该 Nonce 标记为已使用
        userClaimed[msg.sender][token] += amount; //更新用户已领取的空投数量
        MockToken(token).mint(msg.sender, amount); //调用 MockToken 合约的 mint 函数 铸造指定数量的代币 并发送到用户地址
        emit TokensClaimed(msg.sender, token, amount, nonce); //触发 TokensClaimed 事件 记录用户领取空投的信息
    }
    //获取用户已领取的空投数量
    function getUserClaimed(address user,address token) external view returns(uint256){
        return userClaimed[user][token];
    }
}   