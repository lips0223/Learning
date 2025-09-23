// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH 接口
 * @dev Wrapped ETH (WETH) 合约接口，允许ETH与ERC20代币之间的转换
 */
interface IWETH is IERC20 {
    /**
     * @dev 将ETH转换为WETH
     * @notice 调用时需要发送相应数量的ETH
     */
    function deposit() external payable;

    /**
     * @dev 将WETH转换为ETH
     * @param amount 要转换的WETH数量
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev 获取指定地址的WETH余额
     * @param account 查询的地址
     * @return WETH余额
     */
    function balanceOf(address account) external view override returns (uint256);

    /**
     * @dev 转账WETH
     * @param to 接收地址
     * @param amount 转账数量
     * @return 是否成功
     */
    function transfer(address to, uint256 amount) external override returns (bool);

    /**
     * @dev 授权转账WETH
     * @param spender 被授权地址
     * @param amount 授权数量
     * @return 是否成功
     */
    function approve(address spender, uint256 amount) external override returns (bool);

    /**
     * @dev 代理转账WETH
     * @param from 转出地址
     * @param to 接收地址  
     * @param amount 转账数量
     * @return 是否成功
     */
    function transferFrom(address from, address to, uint256 amount) external override returns (bool);
}