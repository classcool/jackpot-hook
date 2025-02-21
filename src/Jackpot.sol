// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { DynamicFeeSlot } from "./DynamicFeeSlot.sol";
import { Lotto, LottoDraw } from "./Lotto.sol";
import { Ball } from "./types/Ball.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
import { LPFeeLibrary } from "v4-core/libraries/LPFeeLibrary.sol";
import { StateLibrary } from "v4-core/libraries/StateLibrary.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";
import { BalanceDelta } from "v4-core/types/BalanceDelta.sol";
import { BeforeSwapDelta } from "v4-core/types/BeforeSwapDelta.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { PoolId } from "v4-core/types/PoolId.sol";
import { BaseHook } from "v4-periphery/src/utils/BaseHook.sol";

contract Jackpot is BaseHook {

    using LPFeeLibrary for uint24;
    using DynamicFeeSlot for uint24;
    using StateLibrary for IPoolManager;

    constructor(IPoolManager _manager) BaseHook(_manager) { }

    mapping(PoolId => mapping(address => LottoDraw[32])) public draws;

    //   | lottoDraw |           |  player address   |
    // 0x010203040506000000000000ffffffffffffffffffff
    event NewLottoDraw(bytes32 indexed draw);

    error DynamicFeeNotSet(uint24 fee);
    error NonNativePoolFeatureError(address token);
    error MinSqrtPriceX96FeatureError(uint160 sqrtPricex96);
    error MaxDrawsCoolCoolCool();

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

    function getDraw(PoolId poolID, address owner) public view returns (LottoDraw[32] memory) {
        return draws[poolID][owner];
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
        // if (sqrtPricex96 != TickMath.MIN_SQRT_PRICE) revert MinSqrtPriceX96FeatureError(sqrtPricex96);

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
        if (hookData.length > 0) {
            LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

            // TODO
            // 2. check if LP wants to share liquidity into the lottery
            // 3. check if LP wants to rebalance some LP liquidity into the Lotto
        }
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
        if (hookData.length > 0) {
            LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

            // TODO
            // 2. update LP lotto stake
            //		- calculate intial stake estimate based of lp position
            //		- (,,) = manager.getPositionInfo()
        }

        return (this.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        // 1. check HookData for LPLottoParams

        if (hookData.length > 0) {
            LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

            // TODO
            // 2. check LP wish to rebalance LP poisition back to into the Lotto
            // 3. calculate LP reward from lotto claim
            //		- check if lotto is done
            //		- check if LP is doing early withdral (surrender liquidity penalty)
            // 4. calculate max LP withdrawal
            //		- check what percentage LP is being withdrawn
            //		- update max liquidity to withdraw
            //		example:
            //		- (,,,) = manager.get.getPositionInfo()
            //		- (,,,) = manager.get.getTickLiquidity()
        }

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
        if (hookData.length > 0) {
            LPLottoParams memory data = abi.decode(hookData, (LPLottoParams));

            // TODO
            // 1. update relevant LP lotto randsom bassed on liquidity
            //		- (,,,) = manager.get.getPositionInfo()
            //		- (,,,) = manager.get.getTickLiquidity()
        }

        return (this.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    struct SwapLottoParams {
        address player;
        LottoDraw draw;
    }

    function _setDraw(PoolId poolID, SwapLottoParams memory params) internal returns (bool isValid) {
        // 1. check valid draw
        (isValid) = params.draw.isValidDraw();

        // 2. update user draw
        if (isValid) {
            if (Ball.unwrap(draws[poolID][params.player][0].ball1) == 0) {
                draws[poolID][params.player][0] = params.draw;
            } else {
                if (Ball.unwrap(draws[poolID][params.player][31].ball1) != 0) {
                    revert MaxDrawsCoolCoolCool();
                }
                for (uint8 i = 1; i < 32; i++) {
                    if (Ball.unwrap(draws[poolID][params.player][i].ball1) == 0) {
                        draws[poolID][params.player][i] = params.draw;
                    }
                }
            }
            emit NewLottoDraw(bytes32(uint256(uint160(params.player))) | params.draw.toPackedBytes());
        }
    }

    function _calculateLottoFee() internal pure returns (uint24 lottoFee) {
        // TODO
        // 1. calculate draw fee using information from the pool
        //		examples:
        //		- (,,,) = manager.getSlot0();

        return LPFeeLibrary.MAX_LP_FEE / 10;
    }

    function _beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata hookData)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // 1. check HookData for lotto params
        if (hookData.length > 0) {
            SwapLottoParams memory data = abi.decode(hookData, (SwapLottoParams));

            // 2. save current dynamic fee to reset fee afterswap
            //		- (,,,) = manager.getSlot0(0)
            (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = poolManager.getSlot0(key.toId());
            lpFee.setPreviousDynamicFee();

            // 3. update dynamic fee before swap
            // TODO: calculate fee based on number draw
            uint24 drawFee = _calculateLottoFee();
            uint24 newFee = drawFee;
            poolManager.updateDynamicLPFee(key, newFee);

            // 4. create lotto entry
            _setDraw(key.toId(), data);
        }

        return (this.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        // 1. check HookData for lotto params
        if (hookData.length > 0) {
            SwapLottoParams memory data = abi.decode(hookData, (SwapLottoParams));

            // 2. update dynamic fee after swap
            (uint24 previousDynamicFee) = DynamicFeeSlot.getPreviousDynamicFee();
            uint24 newFee = previousDynamicFee;
            poolManager.updateDynamicLPFee(key, newFee);

            // TODO
            // 3. update user lotto draws struct
            // 4. check if user is a lotto winner
            // 5. calculate lotto reward
            //		- transfer reward
            //		- close lotto
            //		- update LP ability to withdraw liquidity earnings
        }
        return (this.afterSwap.selector, 0);
    }

}
