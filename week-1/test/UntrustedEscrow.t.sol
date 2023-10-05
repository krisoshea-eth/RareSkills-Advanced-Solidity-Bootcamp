// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/UntrustedEscrow.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract EscrowTest is Test {
    Escrow escrow;
    ERC20PresetMinterPauser token;
    address self;

    function setUp() public {
        self = address(this);
        token = new ERC20PresetMinterPauser("Mock Token", "MTK");
        escrow = new Escrow(address(token));
        token.mint(self, 1000000 * 10 ** uint256(token.decimals()));
    }

    function testDeposit() public {
        uint256 amount = 1000 * 10 ** uint256(token.decimals());

        token.approve(address(escrow), amount);
        escrow.deposit(self, amount);

        assertEq(escrow.depositsOf(self), amount);
    }

    function testFail_WithdrawBeforeTime() public {
        uint256 amount = 1000 * 10 ** uint256(token.decimals());

        token.approve(address(escrow), amount);
        escrow.deposit(self, amount);

        // Attempt to withdraw before the time lock expires
        escrow.withdraw(amount);
    }

    function testWithdraw() public {
        uint256 amount = 1000 * 10 ** uint256(token.decimals());

        token.approve(address(escrow), amount);
        escrow.deposit(self, amount);

        // Warp time to pass the 3-day lock period (259200 seconds)
        vm.warp(block.timestamp + 259201);  // Assuming you're using hevm for time manipulation

        escrow.withdraw(amount);

        assertEq(token.balanceOf(self), 1000000 * 10 ** uint256(token.decimals()));  // Original balance
    }
}

