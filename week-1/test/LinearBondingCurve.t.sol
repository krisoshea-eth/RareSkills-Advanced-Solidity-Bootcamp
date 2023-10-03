// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Test, console2} from "forge-std/Test.sol";
import {LinearBondingCurve} from "../src/modules/LinearBondingCurve.sol";

contract LinearBondingCurveTest is Test {
    LinearBondingCurve public curve;

    // Initialize the contract before running tests
    function setUp() public {
        curve = new LinearBondingCurve();
    }

    // Test initial state
    function testInitialState() public {
        assertEq(curve.initialPrice(), 1 ether);
        assertEq(curve.priceSlope(), 1 ether);
    }

    // Test updating parameters
    function testUpdateParameters() public {
        curve.updateParameters(2 ether, 2 ether);
        assertEq(curve.initialPrice(), 2 ether);
        assertEq(curve.priceSlope(), 2 ether);
    }

    // Test token buying calculation
    function testTokenToEthBuy() public {
        uint256 cost = curve.tokenToEthBuy(0, 10);
        assertEq(cost, 55); // Replace with the expected cost based on your formula
    }

    // Test token selling calculation
    function testTokenToEthSell() public {
        uint256 ethReturn = curve.tokenToEthSell(100, 10);
        assertEq(ethReturn, 45); // Replace with the expected ETH return based on your formula
    }

    // Test how many tokens can be bought with a given amount of ETH
    function testHowManyTokenEthCanBuy() public {
        uint256 tokens = curve.howManyTokenEthCanBuy(100, 1 ether);
        assertEq(tokens, 20); // Replace with the expected token amount based on your formula
    }

    function testEdgeCases() public {
        assertEq(curve.tokenToEthBuy(0, 0), 0, "Cost should be zero for zero tokens");
        assertEq(curve.tokenToEthSell(0, 0), 0, "ETH return should be zero for zero tokens");
    }
    
    function testRevertingTransactions() public {
        bool success = try curve.updateParameters(0, 1 ether);
        require(!success, "Updating with zero initial price should fail");
    
        success = try curve.tokenToEthBuy(0, 0);
        require(!success, "Buying zero tokens should fail");
    
        success = try curve.tokenToEthSell(0, 0);
        require(!success, "Selling zero tokens should fail");
    }
    
    function testAdminOnlyFunctions() public {
        LinearBondingCurve anotherCurve = new LinearBondingCurve();
        bool success = try anotherCurve.updateParameters(2 ether, 2 ether);
        require(!success, "Only admin should be able to update parameters");
    }
    
    function testEvents() public {
        expectEvent("ParametersUpdated", curve.updateParameters(2 ether, 2 ether));
        expectEvent("TokensPurchased", curve.tokenToEthBuy(0, 10));
        expectEvent("TokensSold", curve.tokenToEthSell(100, 10));
    }
    
    function testComplexScenario() public {
        curve.updateParameters(2 ether, 2 ether);
        uint256 cost = curve.tokenToEthBuy(0, 10);
        uint256 ethReturn = curve.tokenToEthSell(10, 5);
        assertEq(ethReturn, cost / 2, "ETH return should be half of the cost for selling half the tokens");
    }

    function testGasUsage() public {
        uint256 gasUsed = gasleft();
        curve.tokenToEthBuy(0, 10);
        gasUsed -= gasleft();
        console.log("Gas Used for tokenToEthBuy: ", gasUsed);
    }
    
    
    // Helper function to assert equality for uint256
    function assertEq(uint256 a, uint256 b) internal {
        require(a == b, "Test failed");
    }
}
