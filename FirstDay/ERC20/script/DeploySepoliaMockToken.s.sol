// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";

contract DeploySepoliaMockToken is Script {
    function setUp() public {}

    function run() public {
        // 从环境变量获取私钥，如果没有设置则使用测试私钥
        uint256 deployerPrivateKey;
        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            deployerPrivateKey = key;
        } catch {
            // 使用 Anvil 默认测试私钥（仅用于测试）
            console.log("Warning: Using default test private key. Set PRIVATE_KEY environment variable for production.");
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying to Sepolia testnet...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // 部署 MockToken 合约
        MockToken token = new MockToken(
            "My Test Token",    // 代币名称
            "MTT",             // 代币符号
            18                 // 小数位数
        );

        console.log("MockToken deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token decimals:", token.decimals());
        console.log("Initial total supply:", token.totalSupply());

        // 可选：铸造一些初始代币给部署者
        uint256 initialMint = 1000000 * 10**18; // 1,000,000 tokens
        token.mint(vm.addr(deployerPrivateKey), initialMint);
        
        console.log("Minted initial supply:", initialMint);
        console.log("Deployer balance:", token.balanceOf(vm.addr(deployerPrivateKey)));

        // 结束广播
        vm.stopBroadcast();

        console.log("Deployment completed successfully!");
        console.log("Contract address:", address(token));
        console.log("Etherscan URL: https://sepolia.etherscan.io/address/", vm.toString(address(token)));
    }
}
