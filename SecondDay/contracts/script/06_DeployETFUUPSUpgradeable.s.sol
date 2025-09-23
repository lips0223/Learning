// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ETFUUPSUpgradeable} from "../src/ETF-Upgradeable/flattened/ETFUUPSUpgradeable_flattened.sol";

contract DeployETFUUPSUpgradeable is Script {
    function run() public {
        vm.startBroadcast();

        // 部署ETFUUPSUpgradeable实现合约
        ETFUUPSUpgradeable etfUUPS = new ETFUUPSUpgradeable();

        console.log("ETFUUPSUpgradeable implementation deployed to:", address(etfUUPS));

        vm.stopBroadcast();
    }
}