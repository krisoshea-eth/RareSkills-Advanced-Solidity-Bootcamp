// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console2} from "forge-std/Test.sol";
import {SanctionToken} from "../src/SanctionToken.sol";

contract MySanctionTokenTest is Test {
    SanctionToken public sanctionToken;
    address minter;
    address sanctioner;
    address user1;
    address user2;

    function setUp() public {
        minter = address(this);
        sanctioner = address(this);
        user1 = address(0x123);
        user2 = address(0x124);
        sanctionToken = new SanctionToken();
    }

    function testMint() public {
        uint256 initialSupply = sanctionToken.totalSupply();
        sanctionToken.mint(user1, 1000);
        uint256 finalSupply = sanctionToken.totalSupply();
        assertEq(finalSupply, initialSupply + 1000);
    }

    function testBan() public {
        sanctionToken.ban(user1);
        assertTrue(sanctionToken.isBanned(user1));
    }

    function testUnban() public {
        sanctionToken.ban(user1);
        sanctionToken.unban(user1);
        assertFalse(sanctionToken.isBanned(user1));
    }

    function testFailBannedUserCannotTransfer() public {
        sanctionToken.mint(user1, 1000);
        sanctionToken.ban(user1);
        sanctionToken.transferFrom(user1, user2, 100); // This should fail
    }

    function testFailCannotSendToBannedUser() public {
        sanctionToken.mint(user1, 1000);
        sanctionToken.ban(user2);
        sanctionToken.transferFrom(user1, user2, 100); // This should fail
    }
}
