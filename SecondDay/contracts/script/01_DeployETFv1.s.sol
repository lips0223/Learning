// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ETFv1} from "../src/ETFv1/ETFv1.sol";

/**
 * @title ETFv1部署脚本
 * @dev 部署ETFv1合约到测试网
 */
contract DeployETFv1 is Script {
    function run() external {
        // 获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // ETF参数配置
        string memory name = "ETF Token v1";
        string memory symbol = "ETFv1";
        
        // 代币地址数组 (Sepolia测试网地址)
        address[] memory tokens = new address[](3);
        tokens[0] = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9; // WETH
        tokens[1] = 0x779877A7B0D9E8603169DdbD7836e478b4624789; // LINK
        tokens[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
        
        // 初始代币数量 (每个ETF份额对应的代币数量)
        uint256[] memory initTokenAmountPerShares = new uint256[](3);
        initTokenAmountPerShares[0] = 1e15; // 0.001 WETH
        initTokenAmountPerShares[1] = 1e18; // 1 LINK
        initTokenAmountPerShares[2] = 1e18; // 1 UNI
        
        uint256 minMintAmount = 1e15; // 最小铸造金额
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署ETFv1合约
        ETFv1 etfv1 = new ETFv1(
            name,
            symbol,
            tokens,
            initTokenAmountPerShares,
            minMintAmount
        );
        
        console.log("ETFv1 deployed to:", address(etfv1));
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Tokens count:", tokens.length);
        
        vm.stopBroadcast();
    }
}