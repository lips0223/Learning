// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {TokenAirDrop} from "../src/TokenAirDrop/TokenAirDrop.sol";

contract DeployTokenAirDropNew is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying NEW TokenAirDrop with deployer:", deployer);
        
        // 部署新的 TokenAirDrop 合约
        TokenAirDrop newAirDrop = new TokenAirDrop(deployer, deployer);
        console.log("NEW TokenAirDrop deployed at:", address(newAirDrop));

        vm.stopBroadcast();

        console.log("\n=== NEW DEPLOYMENT SUMMARY ===");
        console.log("NEW TokenAirDrop:", address(newAirDrop));
        console.log("Signer:", deployer);
        console.log("Owner:", deployer);
        console.log("===============================");
    }
}
