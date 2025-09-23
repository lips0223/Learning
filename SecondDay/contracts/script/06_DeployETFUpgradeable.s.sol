// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFUUPSUpgradeable} from "../src/ETF-Upgradeable/ETFUUPSUpgradeable.sol";
import {ETFProxyFactory} from "../src/ETF-Upgradeable/ETFProxyFactory.sol";

/**
 * @title ETF可升级合约部署脚本
 * @dev 部署ETF可升级合约到测试网
 */
contract DeployETFUpgradeable is Script {
    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. 部署实现合约
        ETFUUPSUpgradeable implementation = new ETFUUPSUpgradeable();
        
        console.log("ETFUUPSUpgradeable implementation deployed to:", address(implementation));
        
        // 2. 部署代理工厂
        ETFProxyFactory factory = new ETFProxyFactory(address(implementation));
        
        console.log("ETFProxyFactory deployed to:", address(factory));
        
        vm.stopBroadcast();
    }
}