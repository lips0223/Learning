// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Uniswap V3接口
interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IUniswapV3Pool {
    function liquidity() external view returns (uint128);
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract CheckLiquidity is Script {
    // Sepolia Uniswap V3地址
    address constant UNISWAP_V3_FACTORY = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    
    // 我们ETF使用的代币
    address constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant ENS = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
    
    // 常见费率
    uint24[3] fees = [500, 3000, 10000]; // 0.05%, 0.3%, 1%
    
    function run() external view {
        console.log("=== Sepolia Uniswap V3 Liquidity Check ===");
        console.log("");
        
        // 检查WETH/LINK
        console.log("1. WETH/LINK Pairs:");
        checkPair(WETH, LINK, "WETH", "LINK");
        
        console.log("");
        
        // 检查WETH/UNI
        console.log("2. WETH/UNI Pairs:");
        checkPair(WETH, UNI, "WETH", "UNI");
        
        console.log("");
        
        // 检查WETH/ENS
        console.log("3. WETH/ENS Pairs:");
        checkPair(WETH, ENS, "WETH", "ENS");
        
        console.log("");
        
        // 检查代币信息
        console.log("4. Token Info:");
        checkTokenInfo(WETH, "WETH");
        checkTokenInfo(LINK, "LINK");
        checkTokenInfo(UNI, "UNI");
        checkTokenInfo(ENS, "ENS");
    }
    
    function checkPair(address token0, address token1, string memory /*symbol0*/, string memory /*symbol1*/) internal view {
        IUniswapV3Factory factory = IUniswapV3Factory(UNISWAP_V3_FACTORY);
        
        for (uint i = 0; i < fees.length; i++) {
            address pool = factory.getPool(token0, token1, fees[i]);
            
            if (pool != address(0)) {
                console.log("  Fee %s: Pool %s", feeToString(fees[i]), pool);
                
                try IUniswapV3Pool(pool).liquidity() returns (uint128 liquidity) {
                    console.log("    Liquidity: %s", uint256(liquidity));
                    
                    try IUniswapV3Pool(pool).slot0() returns (
                        uint160 sqrtPriceX96,
                        int24 tick,
                        uint16,
                        uint16,
                        uint16,
                        uint8,
                        bool
                    ) {
                        console.log("    SqrtPrice: %s", uint256(sqrtPriceX96));
                        console.log("    Tick: %s", tick);
                    } catch {
                        console.log("    Cannot get price info");
                    }
                } catch {
                    console.log("    Cannot get liquidity info");
                }
            } else {
                console.log("  Fee %s: No pool", feeToString(fees[i]));
            }
        }
    }
    
    function checkTokenInfo(address token, string memory symbol) internal view {
        try IERC20(token).symbol() returns (string memory tokenSymbol) {
            try IERC20(token).decimals() returns (uint8 decimals) {
                console.log("  Token Info:");
                console.log("    Symbol:", symbol);
                console.log("    Contract Symbol:", tokenSymbol);
                console.log("    Address:", token);
                console.log("    Decimals:", uint256(decimals));
            } catch {
                console.log("  Token Info:");
                console.log("    Symbol:", symbol);
                console.log("    Contract Symbol:", tokenSymbol);
                console.log("    Address:", token);
                console.log("    Decimals: Cannot get");
            }
        } catch {
            console.log("  Token Info:");
            console.log("    Symbol:", symbol);
            console.log("    Address:", token);
            console.log("    Contract Symbol: Cannot get");
        }
    }
    
    function feeToString(uint24 fee) internal pure returns (string memory) {
        if (fee == 500) return "0.05%";
        if (fee == 3000) return "0.3%";
        if (fee == 10000) return "1%";
        return "unknown";
    }
}