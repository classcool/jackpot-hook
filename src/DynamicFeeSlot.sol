// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DynamicFeeSlot {

    // bytes32(uint256(keccak256("Previous Dynamic Fee slot")) - 1);
    bytes32 constant PREVIOUS_DYNAMIC_FEE_SLOT = 0x0301fe74ae2faa94cc10f333af339db03e5979a3dc81fb969fcc48b1dab05099;

    function setPreviousDynamicFee(uint24 previousFee) internal {
        assembly ("memory-safe") {
            tstore(PREVIOUS_DYNAMIC_FEE_SLOT, previousFee)
        }
    }

    function getPreviousDynamicFee() internal view returns (uint24 previousFee) {
        assembly ("memory-safe") {
            previousFee := tload(PREVIOUS_DYNAMIC_FEE_SLOT)
        }
    }

}
