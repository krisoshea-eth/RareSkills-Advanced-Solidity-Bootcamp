pragma solidity ^0.8.9;

import {Test, console2} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

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

    // Test unauthorized minting
    function testFailUnauthorizedMint() public {
        uint256 mintAmount = 1000;
        MyToken(address(token)).mint(alice, mintAmount);
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
        token.grantRole(MINTER_ROLE, alice);
        token.grantRole(GOD_MODE_ROLE, bob);
    
        // Check roles
        assertTrue(token.hasRole(MINTER_ROLE, alice));
        assertTrue(token.hasRole(GOD_MODE_ROLE, bob));
    
        // Revoke roles
        token.revokeRole(MINTER_ROLE, alice);
        token.revokeRole(GOD_MODE_ROLE, bob);
    
        // Check roles again
        assertFalse(token.hasRole(MINTER_ROLE, alice));
        assertFalse(token.hasRole(GOD_MODE_ROLE, bob));
    }
    
    function testFailMintToZeroAddress() public {
        token.mint(address(0), 1000);
    }
    
    function testFailGodModeTransferToZeroAddress() public {
        token.mint(alice, 1000);
        token.transferGod(alice, address(0), 500);
    }
    
    function testEvents() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 500;
    
        expectEventsExact(token);
        token.mint(alice, mintAmount);
        logsExpectMintEvent(alice, mintAmount);
    
        token.transferGod(alice, bob, transferAmount);
        logsExpectTransferEvent(alice, bob, transferAmount);
    }
    
    function logsExpectMintEvent(address to, uint256 amount) internal {
        log_named_address("LogMintTo:", to);
        log_named_uint("LogMintAmount:", amount);
    }
    
    function logsExpectTransferEvent(address from, address to, uint256 amount) internal {
        log_named_address("LogTransferFrom:", from);
        log_named_address("LogTransferTo:", to);
        log_named_uint("LogTransferAmount:", amount);
    }

    function testFailGodModeTransferBelowMinimum() public {
        uint256 mintAmount = 1000;
        uint256 transferAmount = 1001;
        token.mint(alice, mintAmount);
        token.transferGod(alice, bob, transferAmount);
    }
    
    
}
