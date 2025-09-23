// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ETFProxyFactory} from "../src/ETF-Upgradeable/flattened/ETFProxyFactory_flattened.sol";
import {ETFUUPSUpgradeable} from "../src/ETF-Upgradeable/flattened/ETFUUPSUpgradeable_flattened.sol";

contract DeployETFProxyFactory is Script {
    function run() public {
        vm.startBroadcast();

        // 先部署ETFUUPSUpgradeable作为实现合约
        ETFUUPSUpgradeable implementation = new ETFUUPSUpgradeable();
        
        console.log("ETFUUPSUpgradeable implementation deployed to:", address(implementation));

        // 部署ETFProxyFactory
        ETFProxyFactory factory = new ETFProxyFactory(address(implementation));

        console.log("ETFProxyFactory deployed to:", address(factory));

        vm.stopBroadcast();
    }
}