// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; //Ownable 合约 用于管理合约的所有权
//SafeERC20 库 用于安全地操作 ERC20 代币
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//IERC20 接口 定义了 ERC20 代币的标准接口
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//MerkleTree 合约 继承 Ownable
contract MerkleTree is Ownable {
    using SafeERC20 for IERC20; //using 关键字 用于引入库函数 使 IERC20 类型的变量可以调用 SafeERC20 库中的函数

    address public immutable token; //定义一个 immutable 类型的地址变量 token 用于存储代币合约地址 不可变
    bytes32 public immutable merkleRoot; //定义一个 immutable 类型的字节32变量 merkleRoot 用于存储 Merkle 树的根哈希 不可变
    uint256 public expireAt; //定义一个 uint256 类型的变量 expireAt 用于存储空投过期时间
    //mapping是 Solidity 中的一种数据结构 类似于哈希表或字典
    //uint256 => uint256 表示映射的键和值都是 uint256 类型
    //private 关键字 表示该映射只能在合约内部访问 不能被外部合约或账户访问
    //claimedBitMap 用于存储已领取的空投信息 使用位图方式存储
    //每个 uint256 可以存储 256 个领取状态 每个位表示一个索引的领取状态
    //例如 index 0 对应 claimedBitMap[0] 的第 0 位 index 255 对应 claimedBitMap[0] 的第 255 位
    //index 256 对应 claimedBitMap[1] 的第 0 位 index 511 对应 claimedBitMap[1] 的第 255 位 以此类推    
    mapping(uint256 => uint256) private claimedBitMap; //定义一个私有的映射 claimedBitMap 用于存储已领取的空投信息 使用位图方式存储

    //event 是 solidity 中的一种特殊结构 用于在区块链上记录日志 
    //事件可以被外部监听器捕获 以便在特定操作发生时触发相应的处理逻辑
    //Claimed 事件 在用户成功领取空投时触发
    //uint256 index 用户在 Merkle 树中的索引
    //address account 用户的地址
    //uint256 amount 用户领取的代币数量
    event Claimed(uint256 index, address account, uint256 amount);

    error Expired(); //错误处理 当空投过期时抛出该错误
    error AlreadyClaimed(uint256 index); //错误处理 当用户已领取空投时抛出该错误
    error InvalidProof(); //错误处理 当用户提供的 Merkle 证明无效时抛出该错误

    //初始化构造函数 接受两个参数 token_ 代币合约地址 root_ Merkle 树的根哈希
    //Ownable(msg.sender) 调用父合约 Ownable 的构造函数 将合约拥有者设置为部署者地址
    //token = token_ 将传入的代币合约地址赋值给 token 变量
    //merkleRoot = root_ 将传入的 Merkle 树根哈希赋值给 merkleRoot 变量
    constructor(address token_, bytes32 root_) Ownable(msg.sender) {
        token = token_;
        merkleRoot = root_;
    }

    //setExpireAt 函数 用于设置空投过期时间
    //uint256 expireAt_ 过期时间的时间戳
    //onlyOwner 是 Ownable 合约提供的修饰符 仅允许合约拥有者调用该函数
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //将传入的过期时间赋值给 expireAt 变量  
    function setExpireAt(uint256 expireAt_) external onlyOwner {
        expireAt = expireAt_;
    }
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

    //claim 函数 用于用户领取空投
    //uint256 index 用户在 Merkle 树中的索引
    //address account 用户的地址
    //uint256 amount 用户领取的代币数量
    //bytes32[] calldata merkleProof 用户提供的 Merkle 证明 
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (expireAt > 0 && block.timestamp > expireAt) revert Expired(); //检查空投是否过期 如果过期则抛出 Expired 错误
        if (isClaimed(index)) revert AlreadyClaimed(index); //检查用户是否已领取空投 如果已领取则抛出 AlreadyClaimed 错误

        // 使用 OpenZeppelin/merkle-tree 的 Standard Merkle Tree 哈希算法
        //leaf 是一个字节32类型的变量 用于存储当前用户的叶子节点哈希值
        //keccak256 是以太坊中的一种哈希函数 用于生成固定长度的哈希值
        //bytes.concat 用于将多个字节数组连接成一个字节数组
        //abi.encode 用于将多个参数编码成字节数组
        //index, account, amount 这三个参数用于生成当前用户的叶子节点哈希值
        //如果用户提供的 Merkle 证明无效 则抛出 InvalidProof 错误
        //调用 _verify 函数 验证用户提供的 Merkle 证明 是否有效
        //merkleProof 用户提供的 Merkle 证明
        //merkleRoot 合约中存储的 Merkle 树根哈希
        //leaf 当前用户的叶子节点哈希值 
        //emit Claimed 事件 记录用户成功领取空投的信息
        //index 用户在 Merkle 树中的索引
        //account 用户的地址
        //amount 用户领取的代币数量 
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(index, account, amount)))
        );
        if (!_verify(merkleProof, merkleRoot, leaf)) revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount);
    }
    //isClaimed 函数 用于检查用户是否已领取空投
    //uint256 index 用户在 Merkle 树中的索引
    //public 表示该函数可以被合约内外部访问
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //returns(bool) 表示该函数返回一个布尔值
    //claimedWordIndex 计算用户索引对应的 uint256 索引
    //claimedBitIndex 计算用户索引在对应 uint256 中的位位置
    //claimedWord 从 claimedBitMap 中获取对应的 uint256 值
    //mask 计算出对应位位置的掩码
    //返回 claimedWord 与 mask 的按位与结果是否等于 mask 如果相等 则表示该位已被设置 用户已领取空投 返回 true 否则返回 false
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    //验证用户提供的 Merkle 证明 是否有效
    //bytes32[] memory proof 用户提供的 Merkle 证明
    //bytes32 root 合约中存储的 Merkle 树根哈希
    //bytes32 leaf 当前用户的叶子节点哈希值
    //internal 表示该函数只能在合约内部或继承合约中调用
    //pure 表示该函数不会读取或修改合约状态 仅依赖输入参数进行计算
    //returns(bool) 表示该函数返回一个布尔值
    //computedHash 用于存储当前计算的哈希值 初始值为叶子节点哈希值
    //遍历 Merkle 证明数组 proof 对每个元素进行哈希计算
    //如果当前计算的哈希值小于等于证明元素 则将当前计算的哈希值和证明元素按顺序连接后进行哈希
    //否则将证明元素和当前计算的哈希值按顺序连接后进行哈希
    //最终将计算得到的哈希值与传入的根哈希进行比较 如果相等 则表示证明有效 返回 true 否则返回 false 
    function _verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
    //_setClaimed 函数 用于将指定索引标记为已领取
    //uint256 index 用户在 Merkle 树中的索引
    //internal 表示该函数只能在合约内部或继承合约中调用
    //claimedWordIndex 计算用户索引对应的 uint256 索引
    //claimedBitIndex 计算用户索引在对应 uint256 中的位位置
    //通过位运算 将 claimedBitMap 中对应位置的位设置为 1    
    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }
}
