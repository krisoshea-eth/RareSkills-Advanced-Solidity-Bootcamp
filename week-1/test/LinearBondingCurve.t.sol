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
        uint256 newInitialPrice = 2 ether;
        uint256 newPriceSlope = 2 ether;
    
        // When
        curve.updateParameters(newInitialPrice, newPriceSlope);
    
        // Then
        assertEq(curve.initialPrice(), newInitialPrice);
        assertEq(curve.priceSlope(), newPriceSlope);
    }

    // Test token buying calculation
    function testTokenToEthBuy() public view {
        uint256 currentTokenSupplyInWei = 0;
        uint256 newTokenAmountToBuy = 10;
        uint256 actualCost = curve.testTokenToEthBuy(0, 10);
    }

    // Test token selling calculation
    function testTokenToEthSell() public {
        uint256 ethReturn = curve.testTokenToEthSell(100, 10);
        assertEq(ethReturn, 45); // Replace with the expected ETH return based on your formula
    }

    // Test how many tokens can be bought with a given amount of ETH
    function testHowManyTokenEthCanBuy() public {
        uint256 tokens = curve.testHowManyTokenEthCanBuy(100, 1 ether);
        assertEq(tokens, 20); // Replace with the expected token amount based on your formula
    }

    function testEdgeCases() public {
        assertEq(curve.testTokenToEthBuy(0, 0), 0, "Cost should be zero for zero tokens");
        assertEq(curve.testTokenToEthSell(0, 0), 0, "ETH return should be zero for zero tokens");
    }

    function testRevertingTransactions() public {
        (bool success,) = address(curve).call(abi.encodeWithSelector(curve.updateParameters.selector, 0, 1 ether));
        require(!success, "Updating with zero initial price should fail");

        (success,) = address(curve).call(abi.encodeWithSelector(curve.testTokenToEthBuy.selector, 0, 0));
        require(!success, "Buying zero tokens should fail");

        (success,) = address(curve).call(abi.encodeWithSelector(curve.testTokenToEthSell.selector, 0, 0));
        require(!success, "Selling zero tokens should fail");
    }

    function testComplexScenario() public {
        curve.updateParameters(2 ether, 2 ether);
        uint256 cost = curve.testTokenToEthBuy(0, 10);
        uint256 ethReturn = curve.testTokenToEthSell(10, 5);
        assertEq(ethReturn, cost / 2, "ETH return should be half of the cost for selling half the tokens");
    }

    function testGasUsage() public view {
        uint256 gasUsed = gasleft();
        curve.testTokenToEthBuy(0, 10);
        gasUsed -= gasleft();
        console2.log("Gas Used for tokenToEthBuy: ", gasUsed);
    }

}
