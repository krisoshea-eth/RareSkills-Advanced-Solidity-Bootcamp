// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {Crowdsale} from "../src/Crowdsale.sol";
import {PreventFrontRunners} from "../src/modules/FrontRunnerProtection.sol";
import {LinearBondingCurve} from "../src/modules/LinearBondingCurve.sol";

contract CrowdsaleTest is Test {
    LinearBondingCurve bondingCurve;
    PreventFrontRunners frontRunnerPreventer;
    Crowdsale crowdsale;


    address admin;

    function setUp() public {
        bondingCurve = new LinearBondingCurve(/* constructor arguments here */);
        frontRunnerPreventer = new PreventFrontRunners(/* constructor arguments here */);

        crowdsale = new Crowdsale(
            payable(address(this)),
            bondingCurve,
            frontRunnerPreventer
        );
    }

    function testDeployment() public {
        assertEq(address(crowdsale.owner()), address(this));  // Assuming the deploying address is the owner
    }

    function testReceive() public {
        uint initialBalance = address(crowdsale).balance;
        crowdsale.transfer{value: 1 ether}();  // Sending 1 ether to the contract
        uint finalBalance = address(crowdsale).balance;
        assertEq(finalBalance, initialBalance + 1 ether);  // Testing ether was received
    }

    function testSellTokens() public {
        // Assuming you have a function to mint/buy tokens
        crowdsale.mint(address(this), 100 ether);
        uint initialTokenBalance = crowdsale.balanceOf(address(this));
        crowdsale.sellTokens(50 ether);
        uint finalTokenBalance = crowdsale.balanceOf(address(this));
        assertEq(finalTokenBalance, initialTokenBalance - 50 ether);  // Testing tokens were sold
    }
}

