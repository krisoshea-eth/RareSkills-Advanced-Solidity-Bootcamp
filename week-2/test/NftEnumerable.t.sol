// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {NftEnumerable} from "../src/NftEnumerable.sol";
import {QueryNft} from "../src/QueryNft.sol";

contract NftEnumerableTest is Test {
    NftEnumerable public nftEnumerable;
    QueryNft public queryNft;

    function setUp() public {
        queryNft = new QueryNft(); // You may need to pass arguments to the constructor
        nftEnumerable = new NftEnumerable(queryNft, address(this));
    }

    function test_SafeMint() public {
        nftEnumerable.safeMint(address(this), 21); // Minting a new token with ID 21
        assertEq(nftEnumerable.ownerOf(21), address(this)); // Checking the owner of token ID 21
    }

    function test_QueryNftInteraction() public {
        nftEnumerable.safeMint(address(this), 22); // Minting a new token with ID 22
        queryNft.updatePrimeMapping(22); // Assume updatePrimeMapping is public for this test
        // Replace with actual function call and expected result based on your QueryNft contract logic
        assert(queryNft.isPrimeMapping(22)); // Checking the isPrimeMapping status of token ID 22
    }

    function testFuzz_SafeMint(uint256 tokenId) public {
        // Ensure tokenId is within a reasonable range for testing
        tokenId = tokenId % 100 + 1; // Keeping tokenId between 1 and 100
        nftEnumerable.safeMint(address(this), tokenId);
        assertEq(nftEnumerable.ownerOf(tokenId), address(this));
    }
}
