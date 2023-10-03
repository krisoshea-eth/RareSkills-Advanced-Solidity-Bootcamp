// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Escrow} from "../src/UntrustedEscrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EscrowTest is Test {
    Escrow escrow;
    IERC20 token;

    // Initialize the Escrow contract and a mock ERC20 token before each test
    function beforeEach() public {
        token = new MockERC20("Mock Token", "MTK", 18);
        escrow = new Escrow(address(token));
    }

    // Test the deposit functionality
    function testDeposit() public {
        uint256 amount = 1000;
        address recipient = address(0x123);

        // Approve and deposit tokens into the escrow
        token.approve(address(escrow), amount);
        escrow.deposit(recipient, amount);

        // Check that the deposit was successful
        assertEq(escrow.depositsOf(msg.sender), amount);
    }

    // Test the withdrawal functionality
    function testWithdraw() public {
        uint256 amount = 1000;
        uint256 endTime = block.timestamp + 259200; // 3 days in seconds

        // Approve and deposit tokens into the escrow
        token.approve(address(escrow), amount);
        escrow.deposit(msg.sender, amount);

        // Fast forward time to allow withdrawal
        hevm.warp(endTime);

        // Withdraw tokens from the escrow
        escrow.withdraw(amount, endTime);

        // Check that the withdrawal was successful
        assertEq(token.balanceOf(msg.sender), amount);
    }

    // Test failure when trying to withdraw too early
    function testFailWithdrawTooEarly() public {
        uint256 amount = 1000;

        // Approve and deposit tokens into the escrow
        token.approve(address(escrow), amount);
        escrow.deposit(msg.sender, amount);

        // Attempt to withdraw tokens too early
        escrow.withdraw(amount, block.timestamp + 1);
    }

    // Test failure when trying to withdraw more than the available balance
    function testFailWithdrawInsufficientBalance() public {
        uint256 amount = 1000;
        uint256 endTime = block.timestamp + 259200; // 3 days in seconds

        // Approve and deposit tokens into the escrow
        token.approve(address(escrow), amount);
        escrow.deposit(msg.sender, amount);

        // Fast forward time to allow withdrawal
        hevm.warp(endTime);

        // Attempt to withdraw more tokens than available
        escrow.withdraw(amount + 1, endTime);
    }

 // Test multiple deposits from the same address
function testMultipleDeposits() public {
    uint256 firstAmount = 500;
    uint256 secondAmount = 500;
    address recipient = address(0x123);

    token.approve(address(escrow), firstAmount + secondAmount);
    escrow.deposit(recipient, firstAmount);
    escrow.deposit(recipient, secondAmount);

    assertEq(escrow.depositsOf(msg.sender), firstAmount + secondAmount);
}

// Test deposit of zero amount
function testFailDepositZeroAmount() public {
    escrow.deposit(address(0x123), 0);
}

// Test unauthorized withdrawal
function testFailUnauthorizedWithdrawal() public {
    uint256 amount = 1000;
    uint256 endTime = block.timestamp + 259200; // 3 days in seconds

    token.approve(address(escrow), amount);
    escrow.deposit(msg.sender, amount);

    // Fast forward time to allow withdrawal
    hevm.warp(endTime);

    // Attempt unauthorized withdrawal from another address
    Escrow(address(escrow)).withdraw(amount, endTime);
}

// Test withdrawal exactly when the lock expires
function testWithdrawOnTime() public {
    uint256 amount = 1000;
    uint256 endTime = block.timestamp + 259200; // 3 days in seconds

    token.approve(address(escrow), amount);
    escrow.deposit(msg.sender, amount);

    // Fast forward time to the exact end time
    hevm.warp(endTime);

    escrow.withdraw(amount, endTime);
    assertEq(token.balanceOf(msg.sender), amount);
}

function testMultipleRecipients() public {
    address recipient1 = address(0x123);
    address recipient2 = address(0x456);
    uint256 amount1 = 500;
    uint256 amount2 = 300;

    token.approve(address(escrow), amount1 + amount2);
    escrow.deposit(recipient1, amount1);
    escrow.deposit(recipient2, amount2);

    assertEq(escrow.depositsOf(msg.sender), amount1 + amount2);
}

function testWithdrawByDifferentRecipients() public {
    address recipient1 = address(0x123);
    address recipient2 = address(0x456);
    uint256 amount1 = 500;
    uint256 amount2 = 300;
    uint256 endTime = block.timestamp + 259200; // 3 days in seconds

    token.approve(address(escrow), amount1 + amount2);
    escrow.deposit(recipient1, amount1);
    escrow.deposit(recipient2, amount2);

    // Fast forward time to allow withdrawal
    hevm.warp(endTime);

    // Withdraw by different recipients
    Escrow(address(escrow)).withdraw(amount1, endTime);
    Escrow(address(escrow)).withdraw(amount2, endTime);
}

function testPartialWithdrawals() public {
    uint256 depositAmount = 1000;
    uint256 withdrawAmount = 500;
    uint256 endTime = block.timestamp + 259200; // 3 days in seconds

    token.approve(address(escrow), depositAmount);
    escrow.deposit(msg.sender, depositAmount);

    // Fast forward time to allow withdrawal
    hevm.warp(endTime);

    escrow.withdraw(withdrawAmount, endTime);
    assertEq(token.balanceOf(msg.sender), withdrawAmount);
}

function testOverlappingEndTimes() public {
    uint256 amount = 500;
    uint256 endTime1 = block.timestamp + 259200; // 3 days in seconds
    uint256 endTime2 = block.timestamp + 259200; // 3 days in seconds

    token.approve(address(escrow), amount * 2);
    escrow.deposit(msg.sender, amount);
    escrow.deposit(msg.sender, amount);

    // Fast forward time to allow withdrawal
    hevm.warp(endTime1);

    escrow.withdraw(amount, endTime1);
    escrow.withdraw(amount, endTime2);
}

}
