// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MockToken/MockToken.sol";

contract MintTokens is Script {
    function run() external {
        vm.startBroadcast();

        // MockToken 地址
        address mWBTC = 0x111804f4c285dC5bB4FAc924DA9fD8c721400d15;
        address mWETH = 0xb201F40cC23518Ad433930bD4aA6f1262f2a09D5;
        address mLINK = 0x54350eE868530B4F5826866b25E140a336f1d940;
        address mUSDC = 0x58273fEE3F47ed39C5C2c118725071eF5b5CE418;
        address mUSDT = 0x4692AF93cdA1b91464daD39db41c722B9Dc8F3CF;

        // 获取当前用户地址
        address user = msg.sender;

        // 铸造代币
        MockToken(mWBTC).mint(user, 100 * 10**8);   // 100 mWBTC (8 decimals)
        MockToken(mWETH).mint(user, 1000 * 10**18); // 1000 mWETH (18 decimals)
        MockToken(mLINK).mint(user, 1000 * 10**18); // 1000 mLINK (18 decimals)
        MockToken(mUSDC).mint(user, 10000 * 10**6);  // 10000 mUSDC (6 decimals)
        MockToken(mUSDT).mint(user, 10000 * 10**6);  // 10000 mUSDT (6 decimals)

        console.log("Minted tokens for user:", user);
        console.log("mWBTC:", mWBTC);
        console.log("mWETH:", mWETH);
        console.log("mLINK:", mLINK);
        console.log("mUSDC:", mUSDC);
        console.log("mUSDT:", mUSDT);

        vm.stopBroadcast();
    }
}