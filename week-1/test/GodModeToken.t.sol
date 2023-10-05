pragma solidity ^0.8.9;

import {Test, console2} from "forge-std/Test.sol";
import {MyToken} from "../src/GodModeToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address god;
    address alice;
    address bob;

    function setUp() public {
        god = address(this);
        alice = address(0x1);
        bob = address(0x2);
        token = new MyToken();
    }

    // Test minting tokens
    function testMint() public {
        uint256 initialSupply = 0;
        uint256 mintAmount = 1000;
        assertEq(token.totalSupply(), initialSupply);
        token.mint(alice, mintAmount);
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    // Test God Mode transfer
    function testGodModeTransfer() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 500;
        token.mint(alice, mintAmount);
        token.transferGod(alice, bob, transferAmount);
        assertEq(token.balanceOf(alice), mintAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }

    // Test God Mode transfer with insufficient balance
    function testFailGodModeTransferInsufficientBalance() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 1500;
        token.mint(alice, mintAmount);
        token.transferGod(alice, bob, transferAmount);
    }

    // Test unauthorized God Mode transfer
    function testFailUnauthorizedGodModeTransfer() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 500;
        token.mint(alice, mintAmount);
        MyToken(address(token)).transferGod(alice, bob, transferAmount);
    }

    // Test minting and transferring by God Mode role
    function testMintAndTransferByGod() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 500;
        token.mint(alice, mintAmount);
        token.transferGod(alice, bob, transferAmount);
        assertEq(token.balanceOf(alice), mintAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }

    function testRoleAssignmentAndRevocation() public {
        // Assign roles
        token.grantRole(token.MINTER_ROLE(), alice);
        token.grantRole(token.GOD_MODE_ROLE(), bob);

        // Check roles
        assertTrue(token.hasRole(token.MINTER_ROLE(), alice));
        assertTrue(token.hasRole(token.GOD_MODE_ROLE(), bob));

        // Revoke roles
        token.revokeRole(token.MINTER_ROLE(), alice);
        token.revokeRole(token.GOD_MODE_ROLE(), bob);

        // Check roles again
        assertFalse(token.hasRole(token.MINTER_ROLE(), alice));
        assertFalse(token.hasRole(token.GOD_MODE_ROLE(), bob));
    }

    function testFailMintToZeroAddress() public {
        token.mint(address(0), 1000);
    }

    function testFailGodModeTransferToZeroAddress() public {
        token.mint(alice, 1000);
        token.transferGod(alice, address(0), 500);
    }

    function testFailGodModeTransferBelowMinimum() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 1001;
        token.mint(alice, mintAmount);
        token.transferGod(alice, bob, transferAmount);
    }
}
