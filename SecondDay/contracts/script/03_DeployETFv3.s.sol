// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFv3Lite} from "../src/ETFv3/flattened/ETFv3Lite_flattened.sol";

contract DeployETFv3 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address swapRouter = vm.envAddress("UNISWAP_V3_ROUTER");
        address weth = vm.envAddress("WETH_ADDRESS");
        address ethUsdPriceFeed = vm.envAddress("ETH_USD_PRICE_FEED");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ETFv3Lite etfv3 = new ETFv3Lite(
            swapRouter,
            weth,
            ethUsdPriceFeed
        );
        
        console.log("ETFv3Lite deployed to:", address(etfv3));
        console.log("SwapRouter:", swapRouter);
        console.log("WETH:", weth);
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        
        vm.stopBroadcast();
    }
}
