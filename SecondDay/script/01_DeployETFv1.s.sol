// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFv1} from "../contracts/src/ETFv1/ETFv1.sol";

/**
 * @title ETFv1部署脚本
 * @dev 部署ETFv1合约到测试网
 */
contract DeployETFv1 is Script {
    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署ETFv1合约
        ETFv1 etfv1 = new ETFv1();
        
        console.log("ETFv1 deployed to:", address(etfv1));
        
        vm.stopBroadcast();
    }
}