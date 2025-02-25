// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Jackpot } from "../src/Jackpot.sol";
import { Lotto, LottoDraw } from "../src/Lotto.sol";
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

/// @notice JackpotTest contract
/// @notice Test for deployment and swap logic when submitting lotto draw
contract JackpotTest is Deployers {

    Jackpot hook;

    function setUp() public {
        // 1. deploy v4 core
        deployFreshManagerAndRouters();

        // 2. deploy currencies
        currency0 = Currency.wrap(address(0));
        (currency1) = deployMintAndApproveCurrency();

        // 3. deploy our hook
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
                | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
                | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
        );
        address hookAddress = address(flags);
        deployCodeTo("Jackpot.sol", abi.encode(manager), hookAddress);
        hook = Jackpot(payable(hookAddress));

        // 4. initilize hook
        (key,) = initPool(currency0, currency1, hook, LPFeeLibrary.DYNAMIC_FEE_FLAG, SQRT_PRICE_1_1);

        // 5. add liquidity
        modifyLiquidityRouter.modifyLiquidity{ value: 0.03 ether }(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    function test_CanSubmitLottoDrawDuringTokenSwapSkip() public {
        vm.skip(true);
        // 1. set up user
        address player = makeAddr("Player");
        deal(Currency.unwrap(currency1), player, 10 ether);

        // logs
        uint256 balance0Before = currency0.balanceOfSelf();
        uint256 balance1Before = currency1.balanceOfSelf();
        console.log("currency0 contract before", balance0Before);
        console.log("currency1 contract before", balance1Before);

        uint256 balance0PlayerBefore = currency0.balanceOf(player);
        uint256 balance1PlayerBefore = currency1.balanceOf(player);
        console.log("currency0 player before", balance0PlayerBefore);
        console.log("currency1 player before", balance1PlayerBefore);

        // 2. create lotto draw
        LottoDraw memory lottoDraw = LottoDraw({
            ball1: Ball.wrap(0x01),
            ball2: Ball.wrap(0x02),
            ball3: Ball.wrap(0x03),
            ball4: Ball.wrap(0x04),
            ball5: Ball.wrap(0x05),
            ball6: Ball.wrap(0x06)
        });

        // 3. create swap params
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: false,
            amountSpecified: -1 ether,
            sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE - 1
        });
        PoolSwapTest.TestSettings memory testSettings =
            PoolSwapTest.TestSettings({ takeClaims: false, settleUsingBurn: false });

        // 4. create lotto params
        Jackpot.SwapLottoParams memory lottoParams = Jackpot.SwapLottoParams({ player: player, draw: lottoDraw });
        bytes memory hookData = abi.encode(lottoParams);

        // 5. user performs swap
        vm.startPrank(player);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), 10 ether);
        swapRouter.swap(key, params, testSettings, hookData);
        vm.stopPrank();

        // 6. confirm lotto submitted for user
        LottoDraw[32] memory playerDraws = hook.getDraw(key.toId(), player);
        assertEq(Ball.unwrap(playerDraws[0].ball1), Ball.unwrap(lottoDraw.ball1));
        assertEq(Ball.unwrap(playerDraws[0].ball2), Ball.unwrap(lottoDraw.ball2));
        assertEq(Ball.unwrap(playerDraws[0].ball3), Ball.unwrap(lottoDraw.ball3));
        assertEq(Ball.unwrap(playerDraws[0].ball4), Ball.unwrap(lottoDraw.ball4));
        assertEq(Ball.unwrap(playerDraws[0].ball5), Ball.unwrap(lottoDraw.ball5));
        assertEq(Ball.unwrap(playerDraws[0].ball6), Ball.unwrap(lottoDraw.ball6));

        uint256 balance0ContractAfter = currency0.balanceOfSelf();
        uint256 balance1ContractAfter = currency1.balanceOfSelf();
        console.log("currency0 contract after", balance0ContractAfter);
        console.log("currency1 contract after", balance1ContractAfter);

        uint256 balance0PlayerAfter = currency0.balanceOf(player);
        uint256 balance1PlayerAfter = currency1.balanceOf(player);
        console.log("currency0 player after", balance0PlayerAfter);
        console.log("currency1 player after", balance1PlayerAfter);
    }

    // TODO
    // test ideas
    //	- check for swap directions?
    //		- what does zeroForOne true / false do to purchase price lotto
    //		- what how should fees change with swap directions?
    //	- Lotto price:
    //		options:
    //		1. constant lotto prices regardless of swap
    //		2. dynamic Fees and lotto draw
    //			- check for lp conentrated liquidity on ticks
    //				- what effect do lps have on lotto tickets
    //				- what about JIT liquidity, how can it affect lotto sale and jackpot withdrawals
    //			- check for currenct tick influence in lotto purchase?
    //				- it may be more expensive to purchase lotto in some ticks
    //			- check for sqrt price
    //				- should we use sqrt price, or ticks to calculate price of lotto

}
