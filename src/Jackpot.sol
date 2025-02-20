// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Lotto } from "./Lotto.sol";
import { LottoDraw } from "./LottoDraw.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";
import { BalanceDelta } from "v4-core/types/BalanceDelta.sol";
import { BeforeSwapDelta } from "v4-core/types/BeforeSwapDelta.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { BaseHook } from "v4-periphery/src/utils/BaseHook.sol";

contract Jackpot is BaseHook {

    using Lotto for LottoDraw;

    constructor(IPoolManager _manager) BaseHook(_manager) { }

    mapping(address => LottoDraw) public draws;

    event NewLottoDraw(address player, LottoDraw indexed draw);

    error DynamicFeeNotSet(uint24 fee);
    error NonNativePoolFeatureError(address token);
    error MinSqrtPriceX96FeatureError(uint160 sqrtPricex96);

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function setDraw(LottoDraw memory draw) internal returns (bool isValid) {
        // 1. check valid draw
        (isValid) = draw.isValidDraw();

        // 2. update user draw
        if (isValid) {
            draws[msg.sender] = draw;
            emit NewLottoDraw(msg.sender, draw);
        }
    }

    function getDraw(address user) public view returns (LottoDraw memory) {
        return draws[user];
    }

    function _beforeInitialize(address, PoolKey calldata key, uint160 sqrtPricex96)
        internal
        pure
        override
        returns (bytes4)
    {
        // TODO:
        // 1. Check pool has a dynamic Fee enabled
        if (key.fee != 0x800000) revert DynamicFeeNotSet(key.fee);

        // 2. Experimental feature: Native curreny feature only
        if (Currency.unwrap(key.currency0) != address(0)) {
            revert NonNativePoolFeatureError(Currency.unwrap(key.currency0));
        }

        // 3. Experimental feature: start price at MIN_SQRT_PRICE
        if (sqrtPricex96 != TickMath.MIN_SQRT_PRICE) revert MinSqrtPriceX96FeatureError(sqrtPricex96);

        return this.beforeInitialize.selector;
    }

    struct LPLottoParams {
        bool withdraw;
        uint24 rebalance;
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        // 1. check HookData for LPLottoParams
        LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

        // TODO
        // 2. check if LP wants to share liquidity into the lottery
        // 3. check if LP wants to rebalance some LP liquidity into the Lotto
        return this.beforeAddLiquidity.selector;
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        // 1. check HookData for LPLottoParams
        LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

        // TODO
        // 2. update LP lotto claims

        return (this.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        // 1. check HookData for LPLottoParams
        LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

        // TODO
        // 2. check LP wish to rebalance LP poisition back to into the Lotto
        // 3. calculate LP reward from lotto claim
        //		- check if lotto is done
        //		- check if LP is doing early withdral (surrender liquidity penalty)
        // 4. calculate max LP withdrawal
        //		- check what percentage LP is being withdrawn
        //		- update max liquidity to withdraw

        return this.beforeRemoveLiquidity.selector;
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        // 1. check HookData for LPParams
        LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

        // TODO
        // 1. update remaining LP lotto claims

        return (this.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // TODO
        // 1. check if user wants to make a lotto draw
        // 2. update dynamic fee before swap
        return (this.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // TODO
        // 1. update user lotto draws struct
        // 2. check if user is a lotto winner
        // 3. calculate user reward and transfer and close lotto
        // 4. update LP ability to withdraw claims from closed lotto
        return (this.afterSwap.selector, 0);
    }

}
