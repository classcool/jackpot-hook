// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Deployers } from "@uniswap/v4-core/test/utils/Deployers.sol";
import { Test, console } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/src/test/utils/mocks/MockERC20.sol";
import { Currency, CurrencyLibrary } from "v4-core/PoolManager.sol";
import { IHooks } from "v4-core/interfaces/IHooks.sol";
import { IPoolManager } from "v4-core/interfaces/IPoolManager.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
import { LPFeeLibrary } from "v4-core/libraries/LPFeeLibrary.sol";
import { TickMath } from "v4-core/libraries/TickMath.sol";
import { PoolSwapTest } from "v4-core/test/PoolSwapTest.sol";
import { PoolKey } from "v4-core/types/PoolKey.sol";

contract TestERC6909 is Deployers {

    uint256 tokenId = currency0.toId();
    address v4_user = makeAddr("v4_user");
    address v4_operator = address(this);

    function setUp() public {
        // 1. deploy v4 core
        deployFreshManagerAndRouters();

        // 2. deploy currencies
        currency0 = Currency.wrap(address(0));
        (currency1) = deployMintAndApproveCurrency();

        // 3. initilize hook
        (key,) = initPool(currency0, currency1, IHooks(address(0)), 3000, SQRT_PRICE_1_1);

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

    function test_ERC6909Operator() public {
        deal(Currency.unwrap(currency1), v4_user, 0.01 ether);

        // 1. user mints ERC6909 position
        console.log("0. user currency1 before swap", MockERC20(Currency.unwrap(currency1)).balanceOf(v4_user));
        vm.startPrank(v4_user);
        MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(manager), type(uint256).max);
        bool zeroForOne = false;
        int256 amountSpecified = -0.01 ether;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });
        PoolSwapTest.TestSettings memory settings =
            PoolSwapTest.TestSettings({ takeClaims: true, settleUsingBurn: false });
        swapRouter.swap(key, params, settings, "");
        console.log("1. user currency1 after swap", MockERC20(Currency.unwrap(currency1)).balanceOf(v4_user));
        vm.stopPrank();

        // 2. erc6909 after swap
        console.log("2. user currency0 ERC6909 after swap", manager.balanceOf(v4_user, tokenId));

        // 3. before is user's operator
        console.log("3. isOperator", manager.isOperator(v4_user, v4_operator));

        // 4. sets operator for user by modifying operator storage slot
        uint256 userbalance = manager.balanceOf(v4_user, tokenId);
        vm.startPrank(v4_user);
        manager.setOperator(v4_operator, true);
        vm.stopPrank();
        console.log("4. isOperator", manager.isOperator(v4_user, v4_operator));

        // 5. transfer's user's ERC6909 tokens
        console.log("   currency0 ERC6909 before", manager.balanceOf(v4_operator, tokenId));
        manager.transferFrom(v4_user, v4_operator, tokenId, manager.balanceOf(v4_user, tokenId));
        console.log("5. user currecy0 ERC6909 after", manager.balanceOf(v4_user, tokenId));

        // 6. user ERC6909 balance after
        console.log("6. currency0 ERC6909 after", manager.balanceOf(v4_operator, tokenId));

        // 7. claims tokens on poolmanager by burning tokens
        uint256 balanaceBefore = currency0.balanceOf(v4_operator);
        manager.unlock("");
        console.log("7. net currency0 after claim burn", currency0.balanceOf(v4_operator) - balanaceBefore);
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        manager.take(currency0, v4_operator, manager.balanceOf(v4_operator, tokenId));
        manager.burn(v4_operator, tokenId, manager.balanceOf(v4_operator, tokenId));
    }

}
