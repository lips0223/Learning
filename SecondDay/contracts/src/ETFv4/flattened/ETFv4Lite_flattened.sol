// SPDX-License-Identifier: MIT
pragma solidity <0.9.0 =0.8.24 >=0.4.16 >=0.6.0 >=0.6.2 >=0.8.0 >=0.8.4 ^0.8.0 ^0.8.20 ^0.8.24;

// libraries/BytesLib.sol

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <goncalo.sa@consensys.net>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

/**
 * @title BytesLib 库
 * @dev 用于处理字节数组的工具库，提供切片、类型转换等功能
 */
library BytesLib {
    /**
     * @dev 从字节数组中提取切片
     * @param _bytes 源字节数组
     * @param _start 起始位置
     * @param _length 切片长度
     * @return 切片结果
     */
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely. Copying to the origin's address+32
                // was fine for the last 32-byte chunk when lengthmod == 0, but
                // this last chunk would overwrite the array's length.
                // lengthmod == 0 means the slice starts on a 32-byte word boundary.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * @dev 将字节数组转换为地址
     * @param _bytes 字节数组
     * @param _start 起始位置
     * @return 地址
     */
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    /**
     * @dev 将字节数组转换为 uint24
     * @param _bytes 字节数组
     * @param _start 起始位置
     * @return 24位无符号整数
     */
    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    /**
     * @dev 将字节数组转换为 uint256
     * @param _bytes 字节数组
     * @param _start 起始位置
     * @return 256位无符号整数
     */
    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    /**
     * @dev 连接两个字节数组
     * @param _preBytes 第一个字节数组
     * @param _postBytes 第二个字节数组
     * @return 连接后的字节数组
     */
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    /**
     * @dev 检查两个字节数组是否相等
     * @param _preBytes 第一个字节数组
     * @param _postBytes 第二个字节数组
     * @return 是否相等
     */
    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// libraries/FullMath.sol

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = ~denominator + 1 & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// interfaces/IETFv1.sol

interface IETFv1 {
    error LessThanMinMintAmount();
    error TokenNotFound();
    error TokenExists();

    event Invested(
        address to,
        uint256 mintAmount,
        uint256 investFee,
        uint256[] tokenAmounts
    );
    event Redeemed(
        address sender,
        address to,
        uint256 burnAmount,
        uint256 redeemFee,
        uint256[] tokenAmounts
    );
    event MinMintAmountUpdated(
        uint256 oldMinMintAmount,
        uint256 newMinMintAmount
    );
    event TokenAdded(address token, uint256 index);
    event TokenRemoved(address token, uint256 index);

    function setFee(
        address feeTo_,
        uint24 investFee_,
        uint24 redeemFee_
    ) external;

    function updateMinMintAmount(uint256 newMinMintAmount) external;

    function invest(address to, uint256 mintAmount) external;

    function redeem(address to, uint256 burnAmount) external;

    function feeTo() external view returns (address);

    function investFee() external view returns (uint24);

    function redeemFee() external view returns (uint24);

    function minMintAmount() external view returns (uint256 minMintAmount);

    function getTokens() external view returns (address[] memory);

    function getInitTokenAmountPerShares()
        external
        view
        returns (uint256[] memory);

    function getInvestTokenAmounts(
        uint256 mintAmount
    ) external view returns (uint256[] memory tokenAmounts);

    function getRedeemTokenAmounts(
        uint256 burnAmount
    ) external view returns (uint256[] memory tokenAmounts);
}

// interfaces/IV3SwapRouter.sol

/**
 * @title IV3SwapRouter 接口
 * @dev Uniswap V3 SwapRouter 合约接口，用于代币交换
 */
interface IV3SwapRouter {
    /**
     * @dev 精确输入单笔交换参数结构
     */
    struct ExactInputSingleParams {
        address tokenIn;           // 输入代币地址
        address tokenOut;          // 输出代币地址
        uint24 fee;               // 手续费等级
        address recipient;         // 接收地址
        uint256 deadline;          // 交易截止时间
        uint256 amountIn;          // 输入代币数量
        uint256 amountOutMinimum;  // 最小输出代币数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    /**
     * @dev 精确输出单笔交换参数结构
     */
    struct ExactOutputSingleParams {
        address tokenIn;           // 输入代币地址
        address tokenOut;          // 输出代币地址
        uint24 fee;               // 手续费等级
        address recipient;         // 接收地址
        uint256 deadline;          // 交易截止时间
        uint256 amountOut;         // 输出代币数量
        uint256 amountInMaximum;   // 最大输入代币数量
        uint160 sqrtPriceLimitX96; // 价格限制
    }

    /**
     * @dev 精确输入多跳交换参数结构
     */
    struct ExactInputParams {
        bytes path;               // 交换路径
        address recipient;        // 接收地址
        uint256 deadline;         // 交易截止时间
        uint256 amountIn;         // 输入代币数量
        uint256 amountOutMinimum; // 最小输出代币数量
    }

    /**
     * @dev 精确输出多跳交换参数结构
     */
    struct ExactOutputParams {
        bytes path;              // 交换路径
        address recipient;       // 接收地址
        uint256 deadline;        // 交易截止时间
        uint256 amountOut;       // 输出代币数量
        uint256 amountInMaximum; // 最大输入代币数量
    }

    /**
     * @dev 精确输入单笔交换
     * @param params 交换参数
     * @return amountOut 实际输出的代币数量
     */
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev 精确输出单笔交换
     * @param params 交换参数
     * @return amountIn 实际消耗的输入代币数量
     */
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    /**
     * @dev 精确输入多跳交换
     * @param params 交换参数
     * @return amountOut 实际输出的代币数量
     */
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    /**
     * @dev 精确输出多跳交换
     * @param params 交换参数
     * @return amountIn 实际消耗的输入代币数量
     */
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    /**
     * @dev 多重调用（批量执行多个函数）
     * @param deadline 截止时间
     * @param data 函数调用数据数组
     * @return results 执行结果数组
     */
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    /**
     * @dev 将合约中的代币转给指定地址
     * @param token 代币地址（address(0)表示ETH）
     * @param amountMinimum 最小转出数量
     * @param recipient 接收地址
     */
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /**
     * @dev 退还ETH
     */
    function refundETH() external payable;
}

// lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC165.sol)

// lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC20.sol)

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// interfaces/IETFv2.sol

/**
 * @title IETFv2 接口
 * @dev ETFv2合约的接口定义，继承自IETFv1并添加了ETH投资相关功能
 */
interface IETFv2 is IETFv1 {
    // ============== 错误定义 ==============
    error InvalidSwapPath(bytes path);  // 无效的交换路径
    error InvalidArrayLength();         // 数组长度不匹配
    error ExceedsMaxETHAmount();        // 超出最大ETH数量
    error InsufficientETHAmount();      // ETH数量不足
    error TransferFailed();             // 转账失败
    error OverSlippage();               // 超出滑点限制
    error SafeTransferETHFailed();      // ETH转账失败

    // ============== 事件定义 ==============
    
    /**
     * @dev ETH投资事件
     * @param to 接收ETF份额的地址
     * @param mintAmount 铸造的ETF份额数量
     * @param paidAmount 实际支付的ETH数量
     */
    event InvestedWithETH(
        address indexed to, 
        uint256 mintAmount, 
        uint256 paidAmount
    );
    
    /**
     * @dev 代币投资事件
     * @param srcToken 源代币地址
     * @param to 接收ETF份额的地址
     * @param mintAmount 铸造的ETF份额数量
     * @param paidAmount 实际支付的代币数量
     */
    event InvestedWithToken(
        address indexed srcToken,
        address indexed to, 
        uint256 mintAmount, 
        uint256 paidAmount
    );
    
    /**
     * @dev ETH赎回事件  
     * @param to 接收ETH的地址
     * @param burnAmount 销毁的ETF份额数量
     * @param receivedAmount 接收的ETH数量
     */
    event RedeemedToETH(
        address indexed to, 
        uint256 burnAmount, 
        uint256 receivedAmount
    );
    
    /**
     * @dev 代币赎回事件
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 销毁的ETF份额数量
     * @param receivedAmount 接收的代币数量
     */
    event RedeemedToToken(
        address indexed dstToken,
        address indexed to, 
        uint256 burnAmount, 
        uint256 receivedAmount
    );

        // ============== 函数接口 ==============
    
    /**
     * @dev 使用ETH投资ETF
     * @param to 接收ETF份额的地址
     * @param mintAmount 要铸造的ETF份额数量
     * @param swapPaths Uniswap交换路径数组
     */
    function investWithETH(
        address to,
        uint256 mintAmount,
        bytes[] memory swapPaths
    ) external payable;

    /**
     * @dev 使用指定代币投资ETF
     * @param srcToken 源代币地址
     * @param to 接收ETF份额的地址
     * @param mintAmount 要铸造的ETF份额数量
     * @param maxSrcTokenAmount 最大源代币数量
     * @param swapPaths Uniswap交换路径数组
     */
    function investWithToken(
        address srcToken,
        address to,
        uint256 mintAmount,
        uint256 maxSrcTokenAmount,
        bytes[] memory swapPaths
    ) external;

    /**
     * @dev 赎回ETF获得ETH
     * @param to 接收ETH的地址
     * @param burnAmount 要销毁的ETF份额数量
     * @param minETHAmount 最小接收ETH数量
     * @param swapPaths Uniswap交换路径数组
     */
    function redeemToETH(
        address to,
        uint256 burnAmount,
        uint256 minETHAmount,
        bytes[] memory swapPaths
    ) external;

    /**
     * @dev 赎回ETF获得指定代币
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的ETF份额数量
     * @param minDstTokenAmount 最小接收代币数量
     * @param swapPaths Uniswap交换路径数组
     */
    function redeemToToken(
        address dstToken,
        address to,
        uint256 burnAmount,
        uint256 minDstTokenAmount,
        bytes[] memory swapPaths
    ) external;
}

// interfaces/IWETH.sol

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

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// libraries/Path.sol

/**
 * @title Path 库
 * @dev 用于处理 Uniswap V3 多跳交换路径的工具库
 * @notice 路径格式: token0 → fee0 → token1 → fee1 → token2 ...
 */
library Path {
    using BytesLib for bytes;

    // ============== 常量定义 ==============
    uint256 private constant ADDR_SIZE = 20;        // 地址字节长度
    uint256 private constant FEE_SIZE = 3;          // 手续费字节长度
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;  // 单个跳跃的偏移量
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE; // 弹出一个池子的偏移量
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET; // 多池最小长度

    /**
     * @dev 检查路径是否包含多个池子
     * @param path 编码的交换路径
     * @return 如果包含多个池子返回true，否则返回false
     */
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /**
     * @dev 返回路径中池子的数量
     * @param path 编码的交换路径
     * @return 池子数量
     */
    function numPools(bytes memory path) internal pure returns (uint256) {
        // 忽略第一个代币地址，从那之后每个手续费和代币偏移表示一个池子
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /**
     * @dev 解码路径中的第一个池子
     * @param path 编码的交换路径
     * @return tokenA 第一个代币地址
     * @return tokenB 第二个代币地址  
     * @return fee 池子的手续费等级
     */
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);                    // 第一个代币地址
        fee = path.toUint24(ADDR_SIZE);               // 手续费
        tokenB = path.toAddress(NEXT_OFFSET);         // 第二个代币地址
    }

    /**
     * @dev 获取路径中的第一个代币地址
     * @param path 编码的交换路径
     * @return tokenA 第一个代币地址
     */
    function getFirstToken(bytes memory path) internal pure returns (address tokenA) {
        tokenA = path.toAddress(0);
    }

    /**
     * @dev 获取路径中的最后一个代币地址
     * @param path 编码的交换路径
     * @return tokenB 最后一个代币地址
     */
    function getLastToken(bytes memory path) internal pure returns (address tokenB) {
        tokenB = path.toAddress(path.length - ADDR_SIZE);
    }

    /**
     * @dev 获取路径中第一个池子的手续费等级
     * @param path 编码的交换路径
     * @return fee 第一个池子的手续费等级
     */
    function getFirstFee(bytes memory path) internal pure returns (uint24 fee) {
        fee = path.toUint24(ADDR_SIZE);
    }

    /**
     * @dev 跳过路径中的第一个代币，返回剩余路径
     * @param path 编码的交换路径
     * @return 去掉第一个代币的路径
     */
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }

    /**
     * @dev 验证路径格式是否正确
     * @param path 编码的交换路径
     * @return 路径是否有效
     */
    function isValidPath(bytes memory path) internal pure returns (bool) {
        // 最小路径长度应该是: 地址 + 手续费 + 地址 = 20 + 3 + 20 = 43 字节
        if (path.length < ADDR_SIZE + FEE_SIZE + ADDR_SIZE) {
            return false;
        }
        
        // 检查路径长度是否符合格式要求
        // 应该是: 20 + (23 * n) 其中 n >= 1
        return (path.length - ADDR_SIZE) % NEXT_OFFSET == 0;
    }

    /**
     * @dev 反转路径（用于反向交换）
     * @param path 原始路径
     * @return 反转后的路径
     */
    function reversePath(bytes memory path) internal pure returns (bytes memory) {
        require(isValidPath(path), "Invalid path");
        
        uint256 numPoolsInPath = numPools(path);
        bytes memory reversedPath = new bytes(path.length);
        
        // 反转路径：将最后一个代币放到开头，第一个代币放到最后
        uint256 writeIndex = 0;
        
        // 写入最后一个代币
        bytes memory lastToken = path.slice(path.length - ADDR_SIZE, ADDR_SIZE);
        for (uint256 i = 0; i < ADDR_SIZE; i++) {
            reversedPath[writeIndex++] = lastToken[i];
        }
        
        // 反向写入每个池子的手续费和代币
        for (uint256 i = numPoolsInPath; i > 0; i--) {
            uint256 poolStartIndex = ADDR_SIZE + (i - 1) * NEXT_OFFSET;
            
            // 写入手续费
            bytes memory fee = path.slice(poolStartIndex, FEE_SIZE);
            for (uint256 j = 0; j < FEE_SIZE; j++) {
                reversedPath[writeIndex++] = fee[j];
            }
            
            // 写入代币地址
            bytes memory token = path.slice(poolStartIndex - ADDR_SIZE, ADDR_SIZE);
            for (uint256 j = 0; j < ADDR_SIZE; j++) {
                reversedPath[writeIndex++] = token[j];
            }
        }
        
        return reversedPath;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// lib/openzeppelin-contracts/contracts/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// src/ETFv1/ETFv1.sol

// 导入相关接口和库
      // ETFv1 合约接口标准
   // 高精度数学运算库，防止溢出
           // ERC20 代币标准接口
             // ERC20 代币标准实现
 // 安全的 ERC20 操作库
              // 所有权管理合约

/**
 * @title ETFv1 - 第一版 ETF 合约
 * @dev 实现基础的 ETF 功能：投资、赎回、费用管理
 * @notice 这是一个去中心化的 ETF 产品，用户可以投资一篮子代币并获得 ETF 份额
 */
contract ETFv1 is IETFv1, ERC20, Ownable {
    using SafeERC20 for IERC20;  // 为 IERC20 类型启用 SafeERC20 库的安全操作
    using FullMath for uint256;  // 为 uint256 类型启用高精度数学运算

    // ============== 常量定义 ==============
    uint24 public constant HUNDRED_PERCENT = 1000000; // 100% = 1,000,000 (支持到万分之一的精度)

    // ============== 状态变量 ==============
    address public feeTo;           // 费用接收地址
    uint24 public investFee;        // 投资费用 (万分之几，例如 10000 = 1%)
    uint24 public redeemFee;        // 赎回费用 (万分之几)
    uint256 public minMintAmount;   // 最小铸造金额，防止粉尘攻击

    address[] private _tokens;                        // ETF 包含的代币地址列表
    uint256[] private _initTokenAmountPerShares;      // 每个 ETF 份额对应的初始代币数量（首次投资时使用）

    /**
     * @dev 构造函数 - 初始化 ETF 合约
     * @param name_ ETF 代币名称
     * @param symbol_ ETF 代币符号
     * @param tokens_ ETF 包含的代币地址数组
     * @param initTokenAmountPerShares_ 每个代币对应的初始投资金额数组
     * @param minMintAmount_ 最小铸造金额
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShares_, 
        uint256 minMintAmount_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _tokens = tokens_;
        _initTokenAmountPerShares = initTokenAmountPerShares_;
        minMintAmount = minMintAmount_;
    }

    // ============== 管理员功能 ==============
    
    /**
     * @dev 设置投资和赎回费用 (仅管理员)
     * @param feeTo_ 费用接收地址
     * @param investFee_ 投资费用 (万分之几)
     * @param redeemFee_ 赎回费用 (万分之几)
     */
    function setFee(
        address feeTo_,
        uint24 investFee_,
        uint24 redeemFee_
    ) external onlyOwner {
        feeTo = feeTo_;
        investFee = investFee_;
        redeemFee = redeemFee_;
    }

    /**
     * @dev 更新最小铸造金额 (仅管理员)
     * @param newMinMintAmount 新的最小铸造金额
     */
    function updateMinMintAmount(uint256 newMinMintAmount) external onlyOwner {
        emit MinMintAmountUpdated(minMintAmount, newMinMintAmount);
        minMintAmount = newMinMintAmount;
    }

    // ============== 核心功能 ==============

    /**
     * @dev 投资函数 - 用户投入代币获得 ETF 份额
     * @param to 接收 ETF 份额的地址
     * @param mintAmount 要铸造的 ETF 份额数量
     * @notice 调用前用户需要先授权所有相关代币给本合约
     */
    function invest(address to, uint256 mintAmount) public {
        // 计算需要投入的各种代币数量
        uint256[] memory tokenAmounts = _invest(to, mintAmount);
        
        // 逐个转入用户的代币到合约
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (tokenAmounts[i] > 0) {
                IERC20(_tokens[i]).safeTransferFrom(
                    msg.sender,      // 从调用者
                    address(this),   // 转入到合约
                    tokenAmounts[i]  // 转入数量
                );
            }
        }
    }

    /**
     * @dev 赎回函数 - 用户销毁 ETF 份额获得对应代币
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的 ETF 份额数量
     */
    function redeem(address to, uint256 burnAmount) public {
        _redeem(to, burnAmount);
    }

    // ============== 查询功能 ==============

    /**
     * @dev 获取 ETF 包含的所有代币地址
     * @return 代币地址数组
     */
    function getTokens() public view returns (address[] memory) {
        return _tokens;
    }

    /**
     * @dev 获取每个代币的初始投资金额比例
     * @return 初始金额数组
     */
    function getInitTokenAmountPerShares()
        public
        view
        returns (uint256[] memory)
    {
        return _initTokenAmountPerShares;
    }

    /**
     * @dev 计算投资指定 ETF 份额需要的各代币数量
     * @param mintAmount 要铸造的 ETF 份额数量
     * @return tokenAmounts 需要投入的各代币数量数组
     */
    function getInvestTokenAmounts(
        uint256 mintAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply = totalSupply();  // 当前 ETF 总供应量
        tokenAmounts = new uint256[](_tokens.length);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (totalSupply > 0) {
                // 如果 ETF 已有供应量，按比例计算
                uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
                // 公式: tokenAmount / tokenReserve = mintAmount / totalSupply
                tokenAmounts[i] = tokenReserve.mulDivRoundingUp(
                    mintAmount,
                    totalSupply
                );
            } else {
                // 首次投资，使用初始比例
                tokenAmounts[i] = mintAmount.mulDivRoundingUp(
                    _initTokenAmountPerShares[i],
                    1e18  // 假设 ETF 精度为 18 位
                );
            }
        }
    }

    /**
     * @dev 计算赎回指定 ETF 份额能获得的各代币数量
     * @param burnAmount 要销毁的 ETF 份额数量
     * @return tokenAmounts 能获得的各代币数量数组
     */
    function getRedeemTokenAmounts(
        uint256 burnAmount
    ) public view returns (uint256[] memory tokenAmounts) {
        // 扣除赎回费用
        if (redeemFee > 0) {
            uint256 fee = (burnAmount * redeemFee) / HUNDRED_PERCENT;
            burnAmount -= fee;
        }

        uint256 totalSupply = totalSupply();
        tokenAmounts = new uint256[](_tokens.length);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
            // 公式: tokenAmount / tokenReserve = burnAmount / totalSupply
            tokenAmounts[i] = tokenReserve.mulDiv(burnAmount, totalSupply);
        }
    }

    // ============== 内部功能 ==============

    /**
     * @dev 内部投资逻辑
     * @param to 接收 ETF 份额的地址
     * @param mintAmount 要铸造的数量
     * @return tokenAmounts 需要的各代币数量
     */
    function _invest(
        address to,
        uint256 mintAmount
    ) internal returns (uint256[] memory tokenAmounts) {
        // 检查最小铸造数量
        if (mintAmount < minMintAmount) revert LessThanMinMintAmount();
        
        // 计算需要的代币数量
        tokenAmounts = getInvestTokenAmounts(mintAmount);
        
        uint256 fee;
        if (investFee > 0) {
            // 计算并收取投资费用
            fee = (mintAmount * investFee) / HUNDRED_PERCENT;
            _mint(feeTo, fee);                    // 费用给费用接收地址
            _mint(to, mintAmount - fee);          // 剩余份额给投资者
        } else {
            _mint(to, mintAmount);                // 无费用时全部给投资者
        }

        emit Invested(to, mintAmount, fee, tokenAmounts);
    }

    /**
     * @dev 内部赎回逻辑
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的 ETF 份额数量
     * @return tokenAmounts 返还的各代币数量
     */
    function _redeem(
        address to,
        uint256 burnAmount
    ) internal returns (uint256[] memory tokenAmounts) {
        uint256 totalSupply = totalSupply();
        tokenAmounts = new uint256[](_tokens.length);
        
        // 先销毁用户的 ETF 份额
        _burn(msg.sender, burnAmount);

        uint256 fee;
        if (redeemFee > 0) {
            // 计算并收取赎回费用
            fee = (burnAmount * redeemFee) / HUNDRED_PERCENT;
            _mint(feeTo, fee);  // 将费用以 ETF 形式给费用接收地址
        }

        // 实际用于赎回的数量（扣除费用后）
        uint256 actuallyBurnAmount = burnAmount - fee;
        
        // 按比例返还各种代币
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenReserve = IERC20(_tokens[i]).balanceOf(address(this));
            tokenAmounts[i] = tokenReserve.mulDiv(
                actuallyBurnAmount,
                totalSupply
            );
            // 转出代币给用户（如果目标地址不是合约自身）
            if (to != address(this) && tokenAmounts[i] > 0)
                IERC20(_tokens[i]).safeTransfer(to, tokenAmounts[i]);
        }

        emit Redeemed(msg.sender, to, burnAmount, fee, tokenAmounts);
    }

    // ============== 预留功能（v3版本使用） ==============

    /**
     * @dev 添加新代币到 ETF（内部函数，v3 版本使用）
     * @param token 要添加的代币地址
     * @return index 代币在数组中的索引
     */
    function _addToken(address token) internal returns (uint256 index) {
        // 检查代币是否已存在
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) revert TokenExists();
        }
        index = _tokens.length;
        _tokens.push(token);
        emit TokenAdded(token, index);
    }

    /**
     * @dev 从 ETF 中移除代币（内部函数，v3 版本使用）
     * @param token 要移除的代币地址
     * @return index 被移除代币原来的索引
     */
    function _removeToken(address token) internal returns (uint256 index) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) {
                index = i;
                // 将最后一个元素移到当前位置，然后删除最后一个
                _tokens[i] = _tokens[_tokens.length - 1];
                _tokens.pop();
                emit TokenRemoved(token, index);
                return index;
            }
        }
        revert TokenNotFound();
    }
}

// src/ETFv2/ETFv2.sol

// 导入基础ETFv1合约

// 导入ETFv2接口

// 导入WETH接口

// 导入路径处理库

// 导入OpenZeppelin安全ERC20库

// 导入Uniswap V3交换路由接口

/**
 * @title ETFv2 增强版ETF合约
 * @dev 继承ETFv1的基础功能，增加了ETH投资和任意代币交换功能
 * 支持通过Uniswap V3进行代币交换，实现更灵活的投资和赎回方式
 */
contract ETFv2 is IETFv2, ETFv1 {
    using SafeERC20 for IERC20;
    using Path for bytes;

    // ==================== 状态变量 ====================
    
    /// @dev Uniswap V3交换路由合约地址
    address public immutable swapRouter;
    
    /// @dev WETH代币地址，用于ETH和ERC20代币之间的转换
    address public immutable weth;

    // ==================== 构造函数 ====================
    
    /**
     * @dev 构造函数，初始化ETFv2合约
     * @param name_ ETF代币名称
     * @param symbol_ ETF代币符号
     * @param tokens_ 成分代币地址数组
     * @param initTokenAmountPerShare_ 每份ETF对应的成分代币初始数量
     * @param minMintAmount_ 最小铸造数量
     * @param swapRouter_ Uniswap V3交换路由地址
     * @param weth_ WETH代币地址
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_
    ) ETFv1(name_, symbol_, tokens_, initTokenAmountPerShare_, minMintAmount_) {
        swapRouter = swapRouter_;
        weth = weth_;
    }

    /// @dev 接收ETH的回调函数
    receive() external payable {}

    // ==================== 投资功能 ====================

    /**
     * @dev 使用ETH投资ETF
     * @param to 接收ETF代币的地址
     * @param mintAmount 要铸造的ETF数量
     * @param swapPaths 从WETH到各成分代币的交换路径数组
     */
    function investWithETH(
        address to,
        uint256 mintAmount,
        bytes[] memory swapPaths
    ) external payable {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();
        uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);

        // 将ETH转换为WETH
        uint256 maxETHAmount = msg.value;
        IWETH(weth).deposit{value: maxETHAmount}();
        _approveToSwapRouter(weth);

        uint256 totalPaid;
        // 遍历所有成分代币，执行必要的交换
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], weth, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == weth) {
                // 如果成分代币就是WETH，直接使用
                totalPaid += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换获得所需的成分代币
                totalPaid += IV3SwapRouter(swapRouter).exactOutput(
                    IV3SwapRouter.ExactOutputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountOut: tokenAmounts[i],
                        amountInMaximum: type(uint256).max
                    })
                );
            }
        }

        // 退还多余的ETH
        uint256 leftAfterPaid = maxETHAmount - totalPaid;
        IWETH(weth).withdraw(leftAfterPaid);
        payable(msg.sender).transfer(leftAfterPaid);

        // 执行ETF投资
        _invest(to, mintAmount);

        emit InvestedWithETH(to, mintAmount, totalPaid);
    }

    /**
     * @dev 使用指定代币投资ETF
     * @param srcToken 源代币地址
     * @param to 接收ETF代币的地址
     * @param mintAmount 要铸造的ETF数量
     * @param maxSrcTokenAmount 最大源代币消耗量
     * @param swapPaths 从源代币到各成分代币的交换路径数组
     */
    function investWithToken(
        address srcToken,
        address to,
        uint256 mintAmount,
        uint256 maxSrcTokenAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();
        uint256[] memory tokenAmounts = getInvestTokenAmounts(mintAmount);

        // 转入源代币
        IERC20(srcToken).safeTransferFrom(
            msg.sender,
            address(this),
            maxSrcTokenAmount
        );
        _approveToSwapRouter(srcToken);

        uint256 totalPaid;
        // 遍历所有成分代币，执行必要的交换
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], srcToken, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == srcToken) {
                // 如果成分代币就是源代币，直接使用
                totalPaid += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换获得所需的成分代币
                totalPaid += IV3SwapRouter(swapRouter).exactOutput(
                    IV3SwapRouter.ExactOutputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountOut: tokenAmounts[i],
                        amountInMaximum: type(uint256).max
                    })
                );
            }
        }

        // 退还多余的源代币
        uint256 leftAfterPaid = maxSrcTokenAmount - totalPaid;
        IERC20(srcToken).safeTransfer(msg.sender, leftAfterPaid);

        // 执行ETF投资
        _invest(to, mintAmount);

        emit InvestedWithToken(srcToken, to, mintAmount, totalPaid);
    }

    // ==================== 赎回功能 ====================

    /**
     * @dev 赎回ETF并换取ETH
     * @param to 接收ETH的地址
     * @param burnAmount 要销毁的ETF数量
     * @param minETHAmount 最小接收ETH数量（滑点保护）
     * @param swapPaths 从各成分代币到WETH的交换路径数组
     */
    function redeemToETH(
        address to,
        uint256 burnAmount,
        uint256 minETHAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();

        // 执行ETF赎回，获得成分代币
        uint256[] memory tokenAmounts = _redeem(address(this), burnAmount);

        uint256 totalReceived;
        // 将所有成分代币交换为WETH
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], weth, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == weth) {
                // 如果成分代币就是WETH，直接累加
                totalReceived += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换为WETH
                _approveToSwapRouter(tokens[i]);
                totalReceived += IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: swapPaths[i],
                        recipient: address(this),
                        deadline: block.timestamp + 300,
                        amountIn: tokenAmounts[i],
                        amountOutMinimum: 1
                    })
                );
            }
        }

        // 检查滑点保护
        if (totalReceived < minETHAmount) revert OverSlippage();
        
        // 将WETH转换为ETH并发送
        IWETH(weth).withdraw(totalReceived);
        _safeTransferETH(to, totalReceived);

        emit RedeemedToETH(to, burnAmount, totalReceived);
    }

    /**
     * @dev 赎回ETF并换取指定代币
     * @param dstToken 目标代币地址
     * @param to 接收代币的地址
     * @param burnAmount 要销毁的ETF数量
     * @param minDstTokenAmount 最小接收目标代币数量（滑点保护）
     * @param swapPaths 从各成分代币到目标代币的交换路径数组
     */
    function redeemToToken(
        address dstToken,
        address to,
        uint256 burnAmount,
        uint256 minDstTokenAmount,
        bytes[] memory swapPaths
    ) external {
        address[] memory tokens = getTokens();
        if (tokens.length != swapPaths.length) revert InvalidArrayLength();

        // 执行ETF赎回，获得成分代币
        uint256[] memory tokenAmounts = _redeem(address(this), burnAmount);

        uint256 totalReceived;
        // 将所有成分代币交换为目标代币
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenAmounts[i] == 0) continue;
            
            // 验证交换路径的有效性
            if (!_checkSwapPath(tokens[i], dstToken, swapPaths[i]))
                revert InvalidSwapPath(swapPaths[i]);
                
            if (tokens[i] == dstToken) {
                // 如果成分代币就是目标代币，直接转账
                IERC20(tokens[i]).safeTransfer(to, tokenAmounts[i]);
                totalReceived += tokenAmounts[i];
            } else {
                // 通过Uniswap V3交换为目标代币
                _approveToSwapRouter(tokens[i]);
                totalReceived += IV3SwapRouter(swapRouter).exactInput(
                    IV3SwapRouter.ExactInputParams({
                        path: swapPaths[i],
                        recipient: to,
                        deadline: block.timestamp + 300,
                        amountIn: tokenAmounts[i],
                        amountOutMinimum: 1
                    })
                );
            }
        }

        // 检查滑点保护
        if (totalReceived < minDstTokenAmount) revert OverSlippage();

        emit RedeemedToToken(dstToken, to, burnAmount, totalReceived);
    }

    // ==================== 内部辅助函数 ====================

    /**
     * @dev 为Uniswap路由合约授权代币
     * @param token 要授权的代币地址
     */
    function _approveToSwapRouter(address token) internal {
        if (
            IERC20(token).allowance(address(this), swapRouter) <
            type(uint256).max
        ) {
            IERC20(token).forceApprove(swapRouter, type(uint256).max);
        }
    }

    /**
     * @dev 检查交换路径的有效性
     * @param tokenA 起始代币
     * @param tokenB 结束代币  
     * @param path 交换路径
     * @return 路径是否有效
     */
    function _checkSwapPath(
        address tokenA,
        address tokenB,
        bytes memory path
    ) internal pure returns (bool) {
        (address firstToken, address secondToken, ) = path.decodeFirstPool();
        
        if (tokenA == tokenB) {
            // 同一代币的情况：路径应该是tokenA -> fee -> tokenA且没有多个池子
            if (
                firstToken == tokenA &&
                secondToken == tokenA &&
                !path.hasMultiplePools()
            ) {
                return true;
            } else {
                return false;
            }
        } else {
            // 不同代币的情况：检查路径的起始和结束代币
            if (firstToken != tokenA) return false;
            
            // 跳到路径的最后一个池子
            while (path.hasMultiplePools()) {
                path = path.skipToken();
            }
            (, secondToken, ) = path.decodeFirstPool();
            if (secondToken != tokenB) return false;
            return true;
        }
    }

    /**
     * @dev 安全转账ETH
     * @param to 接收地址
     * @param value 转账金额
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert SafeTransferETHFailed();
    }
}

// src/ETFv4/ETFv4Lite.sol

/**
 * @title ETFv4Lite - 简化版ETFv4合约
 * @dev 移除流动性挖矿等复杂功能，保留核心ETF功能
 */
contract ETFv4Lite is ETFv2 {
    using SafeERC20 for IERC20;
    
    // 协议代币地址
    address public protocolToken;
    
    // 挖矿相关参数（简化版）
    uint256 public rewardRate = 1e18; // 每秒奖励数量
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewards;
    
    event RewardPaid(address indexed user, uint256 reward);
    event ProtocolTokenSet(address indexed token);
    
    /**
     * @dev 构造函数
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory tokens_,
        uint256[] memory initTokenAmountPerShare_,
        uint256 minMintAmount_,
        address swapRouter_,
        address weth_,
        address protocolToken_
    ) ETFv2(name_, symbol_, tokens_, initTokenAmountPerShare_, minMintAmount_, swapRouter_, weth_) {
        protocolToken = protocolToken_;
    }
    
    /**
     * @dev 设置协议代币地址
     */
    function setProtocolToken(address _protocolToken) external onlyOwner {
        protocolToken = _protocolToken;
        emit ProtocolTokenSet(_protocolToken);
    }
    
    /**
     * @dev 更新用户奖励
     */
    function updateReward(address account) internal {
        if (account != address(0)) {
            uint256 userBalance = balanceOf(account);
            if (userBalance > 0) {
                uint256 timeElapsed = block.timestamp - lastUpdateTime[account];
                if (timeElapsed > 0) {
                    rewards[account] += (userBalance * rewardRate * timeElapsed) / 1e18;
                }
            }
            lastUpdateTime[account] = block.timestamp;
        }
    }
    
    /**
     * @dev 领取奖励
     */
    function claimReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            if (protocolToken != address(0)) {
                IERC20(protocolToken).safeTransfer(msg.sender, reward);
            }
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    /**
     * @dev 投资时更新奖励
     */
    function investWithReward(
        address to,
        uint256 amount
    ) external {
        updateReward(to);
        invest(to, amount);
    }
    
    /**
     * @dev 赎回时更新奖励
     */
    function redeemWithReward(
        address to,
        uint256 amount
    ) external {
        updateReward(msg.sender);
        redeem(to, amount);
    }
    
    /**
     * @dev 查看待领取奖励
     */
    function earned(address account) external view returns (uint256) {
        uint256 userBalance = balanceOf(account);
        if (userBalance == 0) return rewards[account];
        
        uint256 timeElapsed = block.timestamp - lastUpdateTime[account];
        return rewards[account] + (userBalance * rewardRate * timeElapsed) / 1e18;
    }
    
    /**
     * @dev 设置奖励速率（仅所有者）
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }
}

