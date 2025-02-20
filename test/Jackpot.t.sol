// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Jackpot } from "../src/Jackpot.sol";
import { Lotto } from "../src/Lotto.sol";
import { LottoDraw } from "../src/LottoDraw.sol";
import { Ball } from "../src/types/Ball.sol";
import { Deployers } from "@uniswap/v4-core/test/utils/Deployers.sol";
import { Test, console } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/src/test/utils/mocks/MockERC20.sol";
import { Currency, CurrencyLibrary } from "v4-core/PoolManager.sol";
import { IPoolManager } from "v4-core/interfaces/IPoolManager.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
import { LPFeeLibrary } from "v4-core/libraries/LPFeeLibrary.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";
import { PoolSwapTest } from "v4-core/test/PoolSwapTest.sol";
import { PoolKey } from "v4-core/types/PoolKey.sol";

contract JackpotTest is Deployers {

    MockERC20 token;
    Jackpot hook;

    Currency token0;
    Currency token1;

    function setUp() public {
        // deploy v4 core
        deployFreshManagerAndRouters();

        // deploy currencies
        token0 = Currency.wrap(address(0));
        (token1) = deployMintAndApproveCurrency();

        // deploy our hook
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
                | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
        );
        address hookAddress = address(flags);
        deployCodeTo("Jackpot.sol", abi.encode(manager), hookAddress);
        hook = Jackpot(hookAddress);

        // initilize hook
        (key,) = initPool(token0, token1, hook, LPFeeLibrary.DYNAMIC_FEE_FLAG, SQRT_PRICE_1_1);

        // add liquidity from -min_tick to +60 tick range
        modifyLiquidityRouter.modifyLiquidity{ value: 299535495591078094 }(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 100 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    function test_CanSubmitLottoDrawDuringTokenSwap() public {
        // 1. set up user
        address player = makeAddr("user");

        LottoDraw memory lottoDraw = LottoDraw({
            ball1: Ball.wrap(1),
            ball2: Ball.wrap(2),
            ball3: Ball.wrap(3),
            ball4: Ball.wrap(4),
            ball5: Ball.wrap(5),
            ball6: Ball.wrap(6)
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: false,
            amountSpecified: 1 ether,
            sqrtPriceLimitX96: 79228162514264337593543950347
        });
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({ takeClaims: false, settleUsingBurn: false });

        Jackpot.SwapLottoParams memory lottoParams = Jackpot.SwapLottoParams({ owner: player, draw: lottoDraw });

        bytes memory hookData = abi.encode(lottoParams);

        swapRouter.swap(key, params, testSettings, hookData);
        LottoDraw[32] memory playerDraws = hook.getDraw(key.toId(), player);
        assertEq(Ball.unwrap(playerDraws[0].ball1), Ball.unwrap(lottoDraw.ball1));
        assertEq(Ball.unwrap(playerDraws[0].ball2), Ball.unwrap(lottoDraw.ball2));
        assertEq(Ball.unwrap(playerDraws[0].ball3), Ball.unwrap(lottoDraw.ball3));
        assertEq(Ball.unwrap(playerDraws[0].ball4), Ball.unwrap(lottoDraw.ball4));
        assertEq(Ball.unwrap(playerDraws[0].ball5), Ball.unwrap(lottoDraw.ball5));
        assertEq(Ball.unwrap(playerDraws[0].ball6), Ball.unwrap(lottoDraw.ball6));
    }

}
