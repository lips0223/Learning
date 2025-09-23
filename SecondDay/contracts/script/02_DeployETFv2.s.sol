// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFv2} from "../src/ETFv2/ETFv2.sol";

contract DeployETFv2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address swapRouter = vm.envAddress("UNISWAP_V3_ROUTER");
        address weth = vm.envAddress("WETH_ADDRESS");
        
        // ETF参数配置
        string memory name = "ETF Token v2";
        string memory symbol = "ETFv2";
        
        // 代币地址数组 (Sepolia测试网地址)
        address[] memory tokens = new address[](3);
        tokens[0] = weth;                                          // WETH
        tokens[1] = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // LINK
        tokens[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
        
        // 初始代币数量 (每个ETF份额对应的代币数量)
        uint256[] memory initTokenAmountPerShare = new uint256[](3);
        initTokenAmountPerShare[0] = 1e15; // 0.001 WETH
        initTokenAmountPerShare[1] = 1e18; // 1 LINK
        initTokenAmountPerShare[2] = 1e18; // 1 UNI
        
        uint256 minMintAmount = 1e15; // 最小铸造金额
        
        vm.startBroadcast(deployerPrivateKey);
        
        ETFv2 etfv2 = new ETFv2(
            name,
            symbol,
            tokens,
            initTokenAmountPerShare,
            minMintAmount,
            swapRouter,
            weth
        );
        
        console.log("ETFv2 deployed to:", address(etfv2));
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("SwapRouter:", swapRouter);
        console.log("WETH:", weth);
        
        vm.stopBroadcast();
    }
}
