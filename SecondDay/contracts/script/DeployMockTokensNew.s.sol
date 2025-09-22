// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MockToken/MockToken.sol";

contract DeployMockTokensNew is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying NEW MockTokens with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        // 部署 Mock WBTC (8 decimals) - 新地址
        MockToken newMockWBTC = new MockToken("New Mock Wrapped Bitcoin", "nWBTC", 8, deployer);
        console.log("New Mock WBTC deployed at:", address(newMockWBTC));

        // 部署 Mock WETH (18 decimals) - 新地址
        MockToken newMockWETH = new MockToken("New Mock Wrapped Ether", "nWETH", 18, deployer);
        console.log("New Mock WETH deployed at:", address(newMockWETH));

        // 部署 Mock LINK (18 decimals) - 新地址
        MockToken newMockLINK = new MockToken("New Mock Chainlink", "nLINK", 18, deployer);
        console.log("New Mock LINK deployed at:", address(newMockLINK));

        // 部署 Mock USDC (6 decimals) - 新地址
        MockToken newMockUSDC = new MockToken("New Mock USD Coin", "nUSDC", 6, deployer);
        console.log("New Mock USDC deployed at:", address(newMockUSDC));

        // 部署 Mock USDT (6 decimals) - 新地址
        MockToken newMockUSDT = new MockToken("New Mock Tether USD", "nUSDT", 6, deployer);
        console.log("New Mock USDT deployed at:", address(newMockUSDT));

        vm.stopBroadcast();

        console.log("\n=== NEW DEPLOYMENT SUMMARY ===");
        console.log("New Mock WBTC:", address(newMockWBTC));
        console.log("New Mock WETH:", address(newMockWETH));
        console.log("New Mock LINK:", address(newMockLINK));
        console.log("New Mock USDC:", address(newMockUSDC));
        console.log("New Mock USDT:", address(newMockUSDT));
        console.log("===============================");
    }
}
