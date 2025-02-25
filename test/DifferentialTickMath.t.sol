// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test, console } from "forge-std/Test.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";

/// @title DifferentialTickMathTest
/// @notice Differential test for TickMath
/// @notice Must have https://github.com/mmsaki/uv4 installed
/// @notice requires `pip install uv4` installed with python >= 3.10
contract DifferentialTickMathTest is Test {

    using Strings for uint256;
    using Strings for int256;

    TickMathBase t;

    function setUp() public {
        t = new TickMathBase();
    }

    // 1. Differential tick -> sqrtPriceX96
    function ffi_sqrt_price_x96_at_tick(int24 x) private returns (uint160) {
        string[] memory inputs = new string[](3);
        inputs[0] = "uv4";
        inputs[1] = "--get_sqrt_price_x96_at_tick";
        if (x < 0) {
            inputs[2] = int256(x).toStringSigned();
        } else {
            inputs[2] = uint256(int256(x)).toString();
        }
        bytes memory res = vm.ffi(inputs);
        uint160 y = abi.decode(res, (uint160));
        return y;
    }

    function testFuzzDifferential_get_sqrt_price_x96_at_tick(int24 x) public {
        bound(x, TickMath.MIN_TICK, TickMath.MAX_TICK);
        vm.assume(x >= TickMath.MIN_TICK);
        vm.assume(x <= TickMath.MAX_TICK);

        uint160 a = ffi_sqrt_price_x96_at_tick(x);
        uint160 b = t.getSqrtPriceAtTick(x);
        assertApproxEqAbs(a, b, 2 ** 96);
        // assertEq(a, b);
    }

    // 2. Differential sqrtPriceX96 -> tick
    function ffi_get_tick_at_sqrt_price_x96(uint160 x) private returns (int24) {
        string[] memory inputs = new string[](3);
        inputs[0] = "uv4";
        inputs[1] = "--get_tick_at_sqrt_price_x96";
        inputs[2] = uint256(x).toString();
        bytes memory res = vm.ffi(inputs);
        int24 y = abi.decode(res, (int24));
        return y;
    }

    function testFuzzDifferential_get_tick_at_sqrt_price_x96(uint160 x) public {
        bound(x, TickMath.MIN_SQRT_PRICE, TickMath.MAX_SQRT_PRICE - 1);
        vm.assume(x >= TickMath.MIN_SQRT_PRICE);
        vm.assume(x < TickMath.MAX_SQRT_PRICE);

        int24 a = ffi_get_tick_at_sqrt_price_x96(x);
        int24 b = t.getTickAtSqrtPrice(x);
        assertApproxEqAbs(a, b, 2 ** 0);
        // assertEq(a, b);
    }

}

contract TickMathBase {

    function getSqrtPriceAtTick(int24 tick) public pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }

    function getTickAtSqrtPrice(uint160 sqrtPriceX96) public pure returns (int24) {
        return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
    }

    function minUsableTick() public pure returns (int24) {
        return TickMath.minUsableTick(TickMath.MIN_TICK_SPACING);
    }

    function maxUsableTick() public pure returns (int24) {
        return TickMath.maxUsableTick(TickMath.MIN_TICK_SPACING);
    }

    // O(log N)
    function square(uint128 x) public returns (uint256) {
        uint256 res = 0;
        uint256 temp = x;
        while (temp > 0) {
            if (temp & 1 == 1) {
                res += x;
            }
            x <<= 1;
            temp >>= 1;
        }
        return res;
    }

}
