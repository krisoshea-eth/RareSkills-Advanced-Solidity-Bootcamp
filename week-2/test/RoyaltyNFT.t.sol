// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RoyaltyNFT} from "../src/RoyaltyNFT.sol";

contract RoyaltyNFTTest is Test {
    RoyaltyNFT public royaltyNFT;
    address constant ARTIST_ADDRESS = address(0x123);
    bytes32 constant MERKLE_ROOT = keccak256("merkleRoot");

    function setUp() public {
        royaltyNFT = new RoyaltyNFT(MERKLE_ROOT, address(this), "https://metadataURI/", ARTIST_ADDRESS);
    }

    function test_mint() public {
        uint256 tokenId = 1;
        uint256 cost = 2 ether;
        royaltyNFT.mint{value: cost}(tokenId, cost);
        assertEq(royaltyNFT.ownerOf(tokenId), address(this));
    }

    function test_discountMint() public {
        uint256 tokenId = 2;
        uint256 cost = 1 ether;
        bytes32[] memory proof = new bytes32[](0);
        uint256 index = 0;
        royaltyNFT.discountMint{value: cost}(proof, index, tokenId, cost);
        assertEq(royaltyNFT.ownerOf(tokenId), address(this));
    }

    function test_listNftForSale() public {
        uint256 tokenId = 1;
        uint256 price = 3 ether;
        royaltyNFT.listNftForSale(tokenId, price);
        assertEq(royaltyNFT.price(tokenId), price);
    }

    function test_secondaryBuy() public {
        uint256 tokenId = 1;
        uint256 buyPrice = 3 ether;
        royaltyNFT.secondaryBuy{value: buyPrice}(tokenId);
        assertEq(royaltyNFT.ownerOf(tokenId), address(this));
    }

    function test_withdrawFunds() public {
        uint256 amount = 1 ether;
        royaltyNFT.withdrawFunds(amount);
        assertEq(address(this).balance, amount);
    }

    function testFail_mint_maxSupplyExceeded() public {
        uint256 tokenId = 21; // Assuming 20 tokens have already been minted
        uint256 cost = 2 ether;
        royaltyNFT.mint{value: cost}(tokenId, cost); // Should fail
    }

    function testFail_discountMint_alreadyMinted() public {
        uint256 tokenId = 1; // Assuming this token has already been discount minted
        uint256 cost = 1 ether;
        bytes32[] memory proof = new bytes32[](0);
        uint256 index = 0;
        royaltyNFT.discountMint{value: cost}(proof, index, tokenId, cost); // Should fail
    }

    function testFail_secondaryBuy_insufficientValue() public {
        uint256 tokenId = 1;
        uint256 buyPrice = 2 ether; // Assuming the sale price is 3 ether
        royaltyNFT.secondaryBuy{value: buyPrice}(tokenId); // Should fail
    }

    function testFail_withdrawFunds_insufficientFunds() public {
        uint256 amount = 10 ether; // Assuming the contract balance is less than 10 ether
        royaltyNFT.withdrawFunds(amount); // Should fail
    }
}
