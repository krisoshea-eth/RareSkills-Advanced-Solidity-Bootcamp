// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test, console2} from "forge-std/Test.sol";
import {PreventFrontRunners} from "../src/modules/FrontRunnerProtection.sol";

contract PreventFrontRunnersTest is Test {
    PreventFrontRunners preventFrontRunners;
    address admin;

    function setUp() public {
        admin = address(this); // For simplicity, the test contract itself is the admin
        preventFrontRunners = new PreventFrontRunners();
        preventFrontRunners.grantRole(preventFrontRunners.ADMIN_ROLE(), admin);
    }

    function test_setMaxGasPrice() public {
        uint256 newMaxGasPrice = 200 gwei;
        preventFrontRunners.setMaxGasPrice(newMaxGasPrice);
        assertEq(preventFrontRunners.maxGasPrice(), newMaxGasPrice);
    }

    function testFail_setMaxGasPriceByNonAdmin() public {
        PreventFrontRunners nonAdminContract = new PreventFrontRunners();
        nonAdminContract.setMaxGasPrice(200 gwei);
    }

    function testFail_setMaxGasPriceTooLow() public {
        preventFrontRunners.setMaxGasPrice(0);
    }

    // Note: Testing enforceNormalGasPrice failure is non-trivial in this setup because you can't easily set tx.gasprice in tests
    function test_enforceNormalGasPrice() public {
        uint256 newMaxGasPrice = 200 gwei;
        preventFrontRunners.setMaxGasPrice(newMaxGasPrice);
        // Assuming tx.gasprice is less than 200 gwei, this should not revert
        preventFrontRunners.enforceNormalGasPrice();
    }

    function test_initialState() public {
        assertEq(preventFrontRunners.maxGasPrice(), 100 gwei);
        assertTrue(preventFrontRunners.hasRole(preventFrontRunners.ADMIN_ROLE(), admin));
    }

    function test_eventEmittedWhenChangingMaxGasPrice() public {
        uint256 newMaxGasPrice = 200 gwei;
        expectEvent("MaxGasPriceChanged", abi.encode(newMaxGasPrice, "wei"));
        preventFrontRunners.setMaxGasPrice(newMaxGasPrice);
    }

    function test_addAndRemoveRoles() public {
        address newAdmin = address(0x123);
        preventFrontRunners.grantRole(preventFrontRunners.ADMIN_ROLE(), newAdmin);
        assertTrue(preventFrontRunners.hasRole(preventFrontRunners.ADMIN_ROLE(), newAdmin));

        preventFrontRunners.revokeRole(preventFrontRunners.ADMIN_ROLE(), newAdmin);
        assertFalse(preventFrontRunners.hasRole(preventFrontRunners.ADMIN_ROLE(), newAdmin));
    }
    
}
