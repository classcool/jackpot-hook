// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LottoDraw } from "./LottoDraw.sol";
import { Ball } from "./types/Ball.sol";

library Lotto {

    Ball constant ZERO_BALL = Ball.wrap(0x00);
    Ball constant MAX_BALL = Ball.wrap(0x31); 

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
