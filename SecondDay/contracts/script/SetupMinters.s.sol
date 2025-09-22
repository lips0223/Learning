// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken/MockToken.sol";

contract SetupMinters is Script {
    // 新部署的扁平化合约地址
    address constant MOCK_WBTC = 0x550a3fc779b68919b378c1925538af7065a2a761;
    address constant MOCK_WETH = 0x237b68901458be70498b923a943de7f885c89943;
    address constant MOCK_LINK = 0x1847d3dba09a81e74b31c1d4c9d3220452ab3973;
    address constant MOCK_USDC = 0x279b091df8fd4a07a01231dcfea971d2abcae0f8;
    address constant MOCK_USDT = 0xda988ddbbb4797affe6efb1b267b7d4b29b604eb;
    
    // 要添加为minter的地址 (你的地址)
    address constant MINTER_ADDRESS = 0xa98C3E7B36d38Ce4f0c15d064a42a4846c979479;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Setting up minters with deployer:", deployer);
        console.log("Adding minter address:", MINTER_ADDRESS);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 为所有MockToken合约添加minter
        MockToken(MOCK_WBTC).addMinter(MINTER_ADDRESS);
        console.log("Added minter to Mock WBTC:", MOCK_WBTC);
        
        MockToken(MOCK_WETH).addMinter(MINTER_ADDRESS);
        console.log("Added minter to Mock WETH:", MOCK_WETH);
        
        MockToken(MOCK_LINK).addMinter(MINTER_ADDRESS);
        console.log("Added minter to Mock LINK:", MOCK_LINK);
        
        MockToken(MOCK_USDC).addMinter(MINTER_ADDRESS);
        console.log("Added minter to Mock USDC:", MOCK_USDC);
        
        MockToken(MOCK_USDT).addMinter(MINTER_ADDRESS);
        console.log("Added minter to Mock USDT:", MOCK_USDT);
        
        vm.stopBroadcast();
        
        console.log("\n=== MINTER SETUP COMPLETE ===");
        console.log("Minter address:", MINTER_ADDRESS);
        console.log("Now you can call mint() on all MockToken contracts!");
        console.log("===============================");
    }
}
