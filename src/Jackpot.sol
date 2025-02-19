// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Lotto } from "./Lotto.sol";
import { LottoDraw } from "./LottoDraw.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
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

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
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

    function setDraw(LottoDraw memory draw) public returns (bool isValid) {
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

    function _beforeInitialize(address, PoolKey calldata key, uint160) internal pure override returns (bytes4) {
        // TODO:
        // 1. Check pool has a dynamic Fee enabled
        if (key.fee != 0x800000) revert DynamicFeeNotSet(key.fee);

        // 2. Feature: Check for ETH as currency0
        require(key.currency0 == Currency.wrap(address(0)), "Non Native pools not supported.");

        return this.beforeInitialize.selector;
    }

    struct JackpotLPParams {
        address lpRewardee;
        int24 tickLower;
        int24 tikUpper;
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        // TODO:
        // Use struct for hookData

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
        // TODO:
        // 1. check hookData struct for JackPot liquidity
        JackpotLPParams memory data = abi.decode(hookData, (JackpotLPParams));
        // if len(
        return (this.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        // TODO:
        return this.beforeRemoveLiquidity.selector;
    }

    function _beforeSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // TODO:
        return (this.beforeSwap.selector, BeforeSwapDelta.wrap(0), 0);
    }

    function _afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // TODO:
        return (this.afterSwap.selector, 0);
    }

}
