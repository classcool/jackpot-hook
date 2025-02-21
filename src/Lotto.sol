// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ball } from "./types/Ball.sol";

using Lotto for LottoDraw global;

struct LottoDraw {
    Ball ball1;
    Ball ball2;
    Ball ball3;
    Ball ball4;
    Ball ball5;
    Ball ball6;
}

library Lotto {

    Ball constant ZERO_BALL = Ball.wrap(0x00);
    Ball constant MAX_BALL = Ball.wrap(0x31);
    bytes32 constant BALL_MASK = 0xFF00000000000000000000000000000000000000000000000000000000000000;

    function fromPackedBytes(bytes6 lottoData) public pure returns (LottoDraw memory lottoDraw) {
        bytes1 ball1;
        bytes1 ball2;
        bytes1 ball3;
        bytes1 ball4;
        bytes1 ball5;
        bytes1 ball6;

        assembly {
            ball1 := and(lottoData, BALL_MASK)
            ball2 := shl(0x08, and(lottoData, shr(0x08, BALL_MASK)))
            ball3 := shl(0x10, and(lottoData, shr(0x10, BALL_MASK)))
            ball4 := shl(0x18, and(lottoData, shr(0x18, BALL_MASK)))
            ball5 := shl(0x20, and(lottoData, shr(0x20, BALL_MASK)))
            ball6 := shl(0x28, and(lottoData, shr(0x28, BALL_MASK)))
        }

        lottoDraw = LottoDraw({
            ball1: Ball.wrap(ball1),
            ball2: Ball.wrap(ball2),
            ball3: Ball.wrap(ball3),
            ball4: Ball.wrap(ball4),
            ball5: Ball.wrap(ball5),
            ball6: Ball.wrap(ball6)
        });
    }

    function toPackedBytes(LottoDraw memory data) public pure returns (bytes6 lottoBytes) {
        assembly {
            let loc := data
            let ball1 := mload(loc)
            let ball2 := shr(0x08, mload(add(loc, 0x20)))
            let ball3 := shr(0x10, mload(add(loc, 0x40)))
            let ball4 := shr(0x18, mload(add(loc, 0x60)))
            let ball5 := shr(0x20, mload(add(loc, 0x80)))
            let ball6 := shr(0x28, mload(add(loc, 0xa0)))
            lottoBytes := or(or(or(or(or(ball1, ball2), ball3), ball4), ball5), ball6)
        }
    }

    function isValidDraw(LottoDraw memory draw) public pure returns (bool) {
        // 1. Check for repeat balls
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(draw.ball2)) return false;
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(draw.ball3)) return false;
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(draw.ball4)) return false;
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(draw.ball5)) return false;
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(draw.ball6)) return false;

        if (Ball.unwrap(draw.ball2) == Ball.unwrap(draw.ball3)) return false;
        if (Ball.unwrap(draw.ball2) == Ball.unwrap(draw.ball4)) return false;
        if (Ball.unwrap(draw.ball2) == Ball.unwrap(draw.ball5)) return false;
        if (Ball.unwrap(draw.ball2) == Ball.unwrap(draw.ball6)) return false;

        if (Ball.unwrap(draw.ball3) == Ball.unwrap(draw.ball4)) return false;
        if (Ball.unwrap(draw.ball3) == Ball.unwrap(draw.ball5)) return false;
        if (Ball.unwrap(draw.ball3) == Ball.unwrap(draw.ball6)) return false;

        if (Ball.unwrap(draw.ball4) == Ball.unwrap(draw.ball5)) return false;
        if (Ball.unwrap(draw.ball4) == Ball.unwrap(draw.ball6)) return false;

        if (Ball.unwrap(draw.ball5) == Ball.unwrap(draw.ball6)) return false;

        // 2. Check balls are between [1, 49]
        if (Ball.unwrap(draw.ball1) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball1) > Ball.unwrap(MAX_BALL)) {
            return false;
        }
        if (Ball.unwrap(draw.ball2) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball2) > Ball.unwrap(MAX_BALL)) {
            return false;
        }
        if (Ball.unwrap(draw.ball3) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball3) > Ball.unwrap(MAX_BALL)) {
            return false;
        }
        if (Ball.unwrap(draw.ball4) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball4) > Ball.unwrap(MAX_BALL)) {
            return false;
        }
        if (Ball.unwrap(draw.ball5) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball5) > Ball.unwrap(MAX_BALL)) {
            return false;
        }
        if (Ball.unwrap(draw.ball6) == Ball.unwrap(ZERO_BALL) || Ball.unwrap(draw.ball6) > Ball.unwrap(MAX_BALL)) {
            return false;
        }

        return true;
    }

}
