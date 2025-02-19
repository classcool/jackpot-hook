// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Jackpot } from "../src/Jackpot.sol";
import { Deployers } from "@uniswap/v4-core/test/utils/Deployers.sol";
import { Test, console } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/src/test/utils/mocks/MockERC20.sol";
import { Currency, CurrencyLibrary } from "v4-core/PoolManager.sol";
import { PoolKey } from "v4-core/types/PoolKey.sol";

import { Hooks } from "v4-core/libraries/Hooks.sol";
import { LPFeeLibrary } from "v4-core/libraries/LPFeeLibrary.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";

contract JackpotTest is Deployers {

    MockERC20 token;
    Jackpot hook;

    Currency token0;
    Currency token1;

    function setUp() public {
        // deploy v4 core
        deployFreshManagerAndRouters();

        // deploy 2 currencies
        (token0, token1) = deployMintAndApprove2Currencies();

        // deploy our hook
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_SWAP_FLAG
                | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );
        address hookAddress = address(flags);
        deployCodeTo("Jackpot.sol", abi.encode(manager), hookAddress);
        hook = Jackpot(hookAddress);

        // initilize hook
        (key,) = initPool(token0, token1, hook, LPFeeLibrary.DYNAMIC_FEE_FLAG, SQRT_PRICE_1_1);
    }

    function test_addLiquidity() public { }

}
