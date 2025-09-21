// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";

contract MockTokenTest is Test {
    MockToken public token;
    address public user1;
    address public user2;

    function setUp() public {
        // 部署测试合约
        token = new MockToken("Test Token", "TEST", 18);
        
        // 创建测试用户
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function test_InitialState() public {
        // 测试初始状态
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    function test_Mint() public {
        // 测试铸造功能
        uint256 amount = 1000 * 10**18; // 1000 tokens
        
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), amount);
    }

    function test_MintMultiple() public {
        // 测试多次铸造
        uint256 amount1 = 500 * 10**18;
        uint256 amount2 = 300 * 10**18;
        
        token.mint(user1, amount1);
        token.mint(user2, amount2);
        
        assertEq(token.balanceOf(user1), amount1);
        assertEq(token.balanceOf(user2), amount2);
        assertEq(token.totalSupply(), amount1 + amount2);
    }

    function test_MintZeroAmount() public {
        // 测试铸造 0 数量
        token.mint(user1, 0);
        
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.totalSupply(), 0);
    }

    function test_MintToZeroAddress() public {
        // 测试铸造到零地址应该失败
        vm.expectRevert();
        token.mint(address(0), 1000 * 10**18);
    }

    function test_CustomDecimals() public {
        // 测试自定义小数位数
        MockToken token6 = new MockToken("USDC", "USDC", 6);
        MockToken token8 = new MockToken("WBTC", "WBTC", 8);
        
        assertEq(token6.decimals(), 6);
        assertEq(token8.decimals(), 8);
    }

    function testFuzz_Mint(address to, uint256 amount) public {
        // 模糊测试
        vm.assume(to != address(0)); // 假设地址不为零
        vm.assume(amount <= type(uint256).max); // 假设数量在合理范围内
        
        token.mint(to, amount);
        
        assertEq(token.balanceOf(to), amount);
        assertEq(token.totalSupply(), amount);
    }
}
