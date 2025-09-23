// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFv4Lite} from "../src/ETFv4/flattened/ETFv4Lite_flattened.sol";

/**
 * @title ETFv4部署脚本
 * @dev 部署ETFv4合约到测试网
 */
contract DeployETFv4 is Script {
    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Sepolia网络地址
        address swapRouter = vm.envAddress("UNISWAP_V3_ROUTER");
        address weth = vm.envAddress("WETH_ADDRESS");
        address etfQuoter = 0x0000000000000000000000000000000000000000; // 暂时使用0地址，稍后可部署
        address protocolToken = 0xF6dAeD439bb765d4886dfEF243DA9A2E8d549499; // 已部署的ETFProtocolToken
        
        // ETF参数
        string memory name = "Blockchain ETF v4";
        string memory symbol = "BETF4";
        address[] memory tokens = new address[](2);
        tokens[0] = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // LINK token on Sepolia
        tokens[1] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI token on Sepolia
        
        uint256[] memory initAmounts = new uint256[](2);
        initAmounts[0] = 10 * 10**18; // 10 LINK per share
        initAmounts[1] = 5 * 10**18;  // 5 UNI per share
        
        uint256 minMintAmount = 1 * 10**18; // 1 ETF minimum
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署ETFv4合约
        ETFv4Lite etfv4 = new ETFv4Lite(
            name,
            symbol,
            tokens,
            initAmounts,
            minMintAmount,
            swapRouter,
            weth,
            protocolToken
        );
        
        console.log("ETFv4 deployed to:", address(etfv4));
        
        vm.stopBroadcast();
    }
}