// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";

contract DeployMockToken is Script {
    function setUp() public {}

    function run() public {
        // 开始广播交易
        vm.startBroadcast();

        // 部署 MockToken 合约
        // 参数：名称、符号、小数位数
        MockToken token = new MockToken(
            "Test Token",  // 代币名称
            "TEST",        // 代币符号
            18             // 小数位数
        );

        console.log("MockToken deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token decimals:", token.decimals());

        // 结束广播
        vm.stopBroadcast();
    }
}
