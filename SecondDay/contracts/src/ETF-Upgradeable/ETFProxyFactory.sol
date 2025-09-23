// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// 导入OpenZeppelin代理合约
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title ETFProxyFactory ETF代理工厂合约
 * @dev 用于创建和管理ETF代理合约的工厂合约
 * 
 * 核心功能：
 * 1. 代理创建：基于Beacon模式创建ETF代理合约
 * 2. 统一升级：支持批量升级所有ETF代理合约
 * 3. 代理管理：追踪和管理所有创建的代理合约
 * 4. 访问控制：只有拥有者才能创建代理和执行升级
 */
contract ETFProxyFactory is UpgradeableBeacon {
    
    // ==================== 状态变量 ====================
    
    /// @dev 存储所有创建的代理合约地址
    address[] public proxies;

    // ==================== 事件定义 ====================
    
    /// @dev 代理合约创建事件
    /// @param etfProxy 新创建的代理合约地址
    event ETFProxyCreated(address indexed etfProxy);
    
    /// @dev 批量升级完成事件
    /// @param newImplementation 新实现合约地址
    /// @param proxyCount 升级的代理数量
    event BatchUpgradeCompleted(address indexed newImplementation, uint256 proxyCount);

    // ==================== 错误定义 ====================
    
    /// @dev 初始化失败错误
    error InitializationFailed();
    
    /// @dev 无效的实现合约错误
    error InvalidImplementation();

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化可升级信标
     * @param implementation ETF实现合约地址
     */
    constructor(
        address implementation
    ) UpgradeableBeacon(implementation, msg.sender) {
        if (implementation == address(0)) revert InvalidImplementation();
    }

    // ==================== 外部函数 ====================
    
    /**
     * @dev 创建新的ETF代理合约（仅拥有者）
     * @param data 初始化数据（包含ETF参数）
     * @return proxy 新创建的代理合约地址
     */
    function createETFProxy(
        bytes memory data
    ) external onlyOwner returns (address proxy) {
        // 创建新的信标代理
        BeaconProxy beaconProxy = new BeaconProxy(address(this), data);
        proxy = address(beaconProxy);
        
        // 记录代理地址
        proxies.push(proxy);
        
        emit ETFProxyCreated(proxy);
    }

    /**
     * @dev 升级所有代理并执行初始化调用（仅拥有者）
     * @param newImplementation 新的实现合约地址
     * @param data 升级后要执行的调用数据
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable onlyOwner {
        // 升级信标指向的实现合约
        upgradeTo(newImplementation);
        
        // 如果有调用数据，对所有代理执行调用
        if (data.length > 0) {
            uint256 length = proxies.length;
            for (uint256 i = 0; i < length; i++) {
                (bool success, ) = proxies[i].call(data);
                if (!success) revert InitializationFailed();
            }
        }
        
        emit BatchUpgradeCompleted(newImplementation, proxies.length);
    }

    /**
     * @dev 仅升级实现合约，不执行调用（仅拥有者）
     * @param newImplementation 新的实现合约地址
     */
    function upgradeImplementation(address newImplementation) external onlyOwner {
        upgradeTo(newImplementation);
        emit BatchUpgradeCompleted(newImplementation, proxies.length);
    }

    // ==================== 视图函数 ====================
    
    /**
     * @dev 获取所有代理合约地址
     * @return 代理合约地址数组
     */
    function getAllProxies() external view returns (address[] memory) {
        return proxies;
    }

    /**
     * @dev 获取代理合约数量
     * @return 代理合约总数
     */
    function getProxyCount() external view returns (uint256) {
        return proxies.length;
    }

    /**
     * @dev 检查地址是否为本工厂创建的代理
     * @param proxy 要检查的地址
     * @return 是否为本工厂创建的代理
     */
    function isProxyCreatedByFactory(address proxy) external view returns (bool) {
        uint256 length = proxies.length;
        for (uint256 i = 0; i < length; i++) {
            if (proxies[i] == proxy) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev 获取指定索引的代理地址
     * @param index 代理索引
     * @return 代理合约地址
     */
    function getProxyAt(uint256 index) external view returns (address) {
        require(index < proxies.length, "Index out of bounds");
        return proxies[index];
    }
}