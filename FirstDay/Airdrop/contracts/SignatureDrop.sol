// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

//双椭圆曲线数字签名算法
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//消息哈希工具
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; //验证合约所有者
//SafeERC20 库 用于安全地操作 ERC20 代币
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//标准ERC20接口
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//SignatureDrop 合约 继承 Ownable
contract SignatureDrop is Ownable {
    using ECDSA for bytes32; //using 关键字 用于引入库函数 使 bytes32 类型的变量可以调用 ECDSA 库中的函数
    using MessageHashUtils for bytes32; //using 关键字 用于引入库函数 使 bytes32 类型的变量可以调用 MessageHashUtils 库中的函数
    using SafeERC20 for IERC20; //using 关键字 用于引入库函数 使 IERC20 类型的变量可以调用 SafeERC20 库中的函数

    address public immutable token; //定义一个 immutable 类型的地址变量 token 用于存储代币合约地址 不可变
    address public signer; //定义一个地址变量 signer 用于存储签名者地址
    //usedNonces 映射 用于存储已使用的 Nonce 防止重放攻击
    //uint256 => bool 表示映射的键是 uint256 类型 值是 bool 类型
    //public 关键字 表示该映射可以被外部合约或账户访问
    //usedNonces[nonce] = true; 表示该 Nonce 已被使用
    //usedNonces[nonce] = false; 表示该 Nonce 未被使用
    mapping(uint256 => bool) public usedNonces;

    //Claimed 事件 在用户成功领取代币时触发
    //address to 用户的地址
    //uint256 amount 用户领取的代币数量
    //uint256 nonce 用户使用的 Nonce
    event Claimed(address to, uint256 amount, uint256 nonce);

    error NonceUsed(); //错误处理 当 Nonce 已被使用时抛出该错误
    error Expired(); //错误处理 当签名过期时抛出该错误
    error InvalidSignature(); //错误处理 当签名无效时抛出该错误


    //初始化构造函数 接受两个参数 token_ 代币合约地址 signer_ 签名者地址
    //Ownable(msg.sender) 调用父合约 Ownable 的构造函数 将合约拥有者设置为部署者地址
    //token = token_ 将传入的代币合约地址赋值给 token 变量
    //signer = signer_ 将传入的签名者地址赋值给 signer 变量 
    constructor(address token_, address signer_) Ownable(msg.sender) {
        token = token_;
        signer = signer_;
    }

    //updateSigner 函数 用于更新签名者地址
    //address signer_ 新的签名者地址
    //onlyOwner 是 Ownable 合约提供的修饰符 仅允许合约拥有者调用该函数
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //将传入的新的签名者地址赋值给 signer 变量
    function updateSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /// @notice  owner withdraw the rest token
    //claimRestTokens 函数 用于合约拥有者提取合约中剩余的代币
    //address to 提取代币的目标地址
    //onlyOwner 是 Ownable 合约提供的修饰符 仅允许合约拥有者调用该函数
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //IERC20(token).balanceOf(address(this)) 调用 IERC20 接口的 balanceOf 函数 查询当前合约地址持有的代币余额
    //this 关键字 表示当前合约实例的地址
    //IERC20(token).safeTransfer(to, balance); 调用 SafeERC20 库中的 safeTransfer 函数 将查询到的余额转账给指定地址 to  
    function claimRestTokens(address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }

    //claim 函数 用于用户领取代币
    //address to 用户的地址 uint256 amount 用户领取的代币数量 uint256 nonce 用户使用的 Nonce
    //uint256 expireAt 签名过期时间的时间戳 bytes memory signature 签名数据
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //if 语句 检查 Nonce 是否已被使用 如果已被使用则抛出 NonceUsed 错误
    //if 语句 检查签名是否过期 如果过期则抛出 Expired 错误
    //verifySignature 函数 用于验证签 名的有效性 如果签名无效则抛出 InvalidSignature 错误
    //usedNonces[nonce] = true; 将该 Nonce 标记为已使用
    //IERC20(token).safeTransfer(to, amount); 调用 SafeERC20 库中的 safeTransfer 函数 将指定金额的代币转账给指定地址 to
    //emit Claimed(to, amount, nonce); 触发 Claimed 事件    
    function claim(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 expireAt,
        bytes memory signature
    ) external {
        if (usedNonces[nonce]) revert NonceUsed();
        if (expireAt < block.timestamp) revert Expired();

        if (!verifySignature(to, amount, nonce, expireAt, signature))
            revert InvalidSignature();

        usedNonces[nonce] = true;
        IERC20(token).safeTransfer(to, amount);

        emit Claimed(to, amount, nonce);
    }

    //verifySignature 函数 用于验证签名的有效性
    //address to 用户的地址 uint256 amount 用户领取的代币数量 uint256 nonce 用户使用的 Nonce
    //uint256 expireAt 签名过期时间的时间戳 bytes memory signature 签名数据
    //public 表示该函数可以被合约内部和外部调用
    //view 表示该函数不会修改区块链状态 仅用于读取数据
    //bytes32 messageHash = getMessageHash(to, amount, nonce, expireAt); 调用 getMessageHash 函数 生成消息哈希
    //bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash); 调用 getEthSignedMessageHash 函数 生成以太坊签名消息哈希
    //address recovered = ethSignedMessageHash.recover(signature); 调用 ECDSA 库中的 recover 函数 从签名中恢复出签名者地址
    //return recovered == signer; 检查恢复出的签名者地址是否与存储的签名者地址相同 如果相同则返回 true 否则返回 false   
    function verifySignature(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 expireAt,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(to, amount, nonce, expireAt);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address recovered = ethSignedMessageHash.recover(signature);
        return recovered == signer;
    }
    //获取消息哈希
    //address to 用户的地址 uint256 amount 用户领取的代币数量 uint256 nonce 用户使用的 Nonce
    //uint256 expireAt 签名过期时间的时间戳
    //public 表示该函数可以被合约内部和外部调用 
    //pure 表示该函数不会读取或修改区块链状态 仅用于计算和返回数据
    //returns(bytes32) 表示该函数返回一个 bytes32 类型的值
    //abi.encodePacked 用于将多个参数编码成一个字节数组
    //keccak256 是以太坊中的一种哈希函数 用于生成固定长度的哈希值
    function getMessageHash(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 expireAt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, amount, nonce, expireAt));
    }
    //getEthSignedMessageHash 函数 用于生成以太坊签名消息哈希
    //bytes32 messageHash 消息哈希
    //public 表示该函数可以被合约内部和外部调用
    //pure 表示该函数不会读取或修改区块链状态 仅用于计算和返回数据
    //returns(bytes32) 表示该函数返回一个 bytes32 类型的值
    //调用 MessageHashUtils 库中的 toEthSignedMessageHash 函数生成以太坊签名消息哈希
    function getEthSignedMessageHash(
        bytes32 messageHash
    ) public pure returns (bytes32) {
        return messageHash.toEthSignedMessageHash();
    }
}
