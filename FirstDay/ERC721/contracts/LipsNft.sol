// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//引入openzeppelin的ERC721合约 用于实现NFT标准
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// 引入ERC721Enumerable 用于实现可枚举的NFT
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//引入Ownable 用于权限管理
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//ERC721Enumerable 是 OpenZeppelin 提供的一个 ERC721 扩展合约，它在标准 ERC721 协议基础上增加了 枚举功能，允许查询 NFT 的集合信息和用户持有的 NFT 列表。
// ERC721Enumerable 继承自 ERC721，因此 LipsNft 合约通过多重继承同时获得了 ERC721 和 ERC721Enumerable 的功能。
// Ownable 提供了基本的权限控制机制，允许合约拥有者执行特定操作。
// ERC721Enumerable 核心作用：
/**
 * 1. 总供应量查询：可以查询合约中所有铸造的 NFT 的总数量。 totalSupply() 函数返回当前合约中存在的 NFT 总数。
 * 2. 按索引查询 NFT：可以通过索引值查询合约 中所有 NFT 的 tokenId。 tokenByIndex(uint256 index) 函数返回指定索引位置的 NFT 的 tokenId。
 * 3. 按持有者查询 NFT：可以查询某个地址持有的所有 NFT 的 tokenId 列表。 tokensOfOwner(address owner) 函数返回指定地址持有的所有 NFT 的 tokenId 数组。
 * 4. 按持有者和索引查询 NFT：可以通过持有者地址和索引值查询该地址持有的特定 NFT 的 tokenId。 tokenOfOwnerByIndex(address owner, uint256 index) 函数返回指定地址持有的特定索引位置的 NFT 的 tokenId。
 */

//定义 LipsNft 合约 继承 ERC721,ERC721Enumerable,Ownable
contract LipsNft is ERC721, ERC721Enumerable, Ownable {
    //public 为可见性修饰符 表示该变量可以被合约内外部访问
    //constant 表示该变量是常量 其值在合约部署后不可
    //MAX_SUPPLY 是一个常量变量 用于定义NFT的最大供应量为10000
    //uint256 是Solidity中的一种数据类型 表示无符号整数
    uint256 public constant MAX_SUPPLY = 10000; //最大供应量
    uint256 private _nextTokenId; //下一个tokenId
    string private _baseTokenURI; //基础URI 用于存储NFT的元数据地址前缀
    error AllMinted(); // 错误处理 当所有NFT都被铸造时抛出该错误
    constructor() ERC721("LipsNft", "LIPS") Ownable(msg.sender){} //构造函数 初始化ERC721合约的名称和符号 并将合约拥有者设置为部署者
    //重写 baseURI 函数 返回基础URI
    //memory 表示该字符串存储在内存中
    //onlyOwner 是 Ownable 合约提供的修饰符 仅允许合约拥有者调用该函数
    //external 表示该函数只能被合约外部调用 不能被合约内部调用
    //setBaseURI 函数 用于设置基础URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    //重写 safeMint 函数 用于安全铸造NFT    
    function safeMint(address to) external onlyOwner {
        if (_nextTokenId >= MAX_SUPPLY) { //检查是否达到最大供应量
            revert AllMinted();
        }
        uint256 tokenId = _nextTokenId; //定义 tokenId 变量 并将其设置为当前的下一个 tokenId
        _nextTokenId++; //递增下一个tokenId
        _safeMint(to, tokenId); //调用 _safeMint 函数 将 NFT 铸造给指定地址 to
    }

    //重写 supportInterface 函数 用于支持接口查询
    //override 关键字 表示该函数重写了父合约中的同名函数
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //returns(bool) 表示该函数返回一个布尔值
    //super 关键字 用于调用父合约中的函数
    function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721Enumerable) returns(bool){
        return super.supportsInterface(interfaceId);
    }
    //重写 _update 函数 用于更新NFT的所有权信息
    //internal 表示该函数只能在合约内部或继承合约中调用
    //override(ERC721,ERC721Enumerable) 表示该函数重写了 ERC721 和 ERC721Enumerable 合约中的同名函数
    // super 关键字 用于调用父合约中的函数
    function _update(address to,uint256 tokenId,address auth) internal override(ERC721,ERC721Enumerable) returns (address) {
        return super._update(to,tokenId,auth);
    }
    //重写 _increaseBalance 函数 用于增加账户的NFT余额
    //internal 表示该函数只能在合约内部或继承合约中调用
    //override(ERC721,ERC721Enumerable) 表示该函数重写了 ERC721 和 ERC721Enumerable 合约中的同名函数
    // super 关键字 用于调用父合约中的函数
    function _increaseBalance(address account,uint128 value) internal override(ERC721,ERC721Enumerable) {
        return super._increaseBalance(account,value);
    }

    //重写 _baseURI 函数 返回基础URI
    //internal 表示该函数只能在合约内部或继承合约中调用
    //view 表示该函数不会修改合约状态 仅用于读取数据
    //override 表示该函数重写了父合约中的同名函数   
    //memory 表示该字符串存储在内存中
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
