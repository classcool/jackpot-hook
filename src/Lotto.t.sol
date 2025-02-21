// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import { Lotto, LottoDraw } from "./Lotto.sol";
import { Ball } from "./types/Ball.sol";
import { Test, console } from "forge-std/Test.sol";

contract LottoTest is Test {

    function setUp() public { }

    function test_LottoToPackedBytes() public pure {
        LottoDraw memory lottoDraw = LottoDraw({
            ball1: Ball.wrap(0x01),
            ball2: Ball.wrap(0x02),
            ball3: Ball.wrap(0x03),
            ball4: Ball.wrap(0x04),
            ball5: Ball.wrap(0x05),
            ball6: Ball.wrap(0x06)
        });
        bytes6 lottoBytes = Lotto.toPackedBytes(lottoDraw);
        assertEq(abi.encodePacked(lottoBytes), abi.encodePacked(hex"010203040506"));
    }

    function test_LottoFromPackedBytes() public pure {
        bytes6 lottoBytes = 0x010203040506;
        LottoDraw memory lottoDraw = Lotto.fromPackedBytes(lottoBytes);

        LottoDraw memory lottoDrawExpected = LottoDraw({
            ball1: Ball.wrap(0x01),
            ball2: Ball.wrap(0x02),
            ball3: Ball.wrap(0x03),
            ball4: Ball.wrap(0x04),
            ball5: Ball.wrap(0x05),
            ball6: Ball.wrap(0x06)
        });
        assertEq(abi.encode(lottoDraw), abi.encode(lottoDrawExpected));
    }

    function test_LottoValidLottoDrawRepeatBall() public pure {
        LottoDraw memory lottoDraw = LottoDraw({
            ball1: Ball.wrap(0x01),
            ball2: Ball.wrap(0x02),
            ball3: Ball.wrap(0x03),
            ball4: Ball.wrap(0x04),
            ball5: Ball.wrap(0x05),
            ball6: Ball.wrap(0x05)
        });
        assertFalse(lottoDraw.isValidDraw());
    }

    function test_LottoValidLottoDrawOutOfBoundBall() public pure {
        LottoDraw memory lottoDraw = LottoDraw({
            ball1: Ball.wrap(0x01),
            ball2: Ball.wrap(0x02),
            ball3: Ball.wrap(0x03),
            ball4: Ball.wrap(0x04),
            ball5: Ball.wrap(0x05),
            ball6: Ball.wrap(0x35)
        });
        assertFalse(lottoDraw.isValidDraw());
    }

}
