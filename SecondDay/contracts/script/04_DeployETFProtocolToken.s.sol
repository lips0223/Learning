// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFProtocolToken} from "../src/ETFv4/ETFProtocolToken.sol";

/**
 * @title ETFProtocolToken部署脚本
 * @dev 部署ETFProtocolToken合约到测试网
 */
contract DeployETFProtocolToken is Script {
    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署ETFProtocolToken合约
        ETFProtocolToken protocolToken = new ETFProtocolToken(
            deployer, // defaultAdmin
            deployer  // minter
        );
        
        console.log("ETFProtocolToken deployed to:", address(protocolToken));
        
        vm.stopBroadcast();
    }
}