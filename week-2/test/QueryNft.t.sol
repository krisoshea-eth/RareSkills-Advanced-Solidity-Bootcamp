// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {QueryNft} from "../src/QueryNft.sol";
import {NftEnumerable} from "../src/NftEnumerable.sol";

contract QueryNftTest is Test {
    QueryNft public queryNft;
    NftEnumerable public nftEnumerable;

    function setUp() public {
        nftEnumerable = new NftEnumerable(address(this)); // Assumes the NftEnumerable contract takes the owner's address as a parameter
        queryNft = new QueryNft(nftEnumerable);
    }

    function test_updatePrimeMapping() public {
        queryNft.updatePrimeMapping(2);
        assertEq(queryNft.isPrimeMapping(2), true);
    }

    function test_numOfPrimeTokenIds() public {
        nftEnumerable.safeMint(address(this), 3); // Assumes the safeMint function is available and public
        queryNft.updatePrimeMapping(3);
        assertEq(queryNft.numOfPrimeTokenIds(address(this)), 1);
    }

    function test_checkPrime() public {
        assertEq(queryNft.checkPrime(5), true);
        assertEq(queryNft.checkPrime(6), false);
    }

    function test_sqrt() public {
        assertEq(queryNft.sqrt(9), 3);
        assertEq(queryNft.sqrt(16), 4);
    }

    function testFuzz_updatePrimeMapping(uint256 tokenId) public {
        tokenId = tokenId % 1000 + 1; // Keeping tokenId between 1 and 1000
        queryNft.updatePrimeMapping(tokenId);
        assertEq(queryNft.isPrimeMapping(tokenId), queryNft.checkPrime(tokenId));
    }
}
