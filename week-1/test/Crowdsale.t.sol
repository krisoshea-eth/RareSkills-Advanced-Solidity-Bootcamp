// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {Crowdsale} from "../src/Crowdsale.sol";
import {PreventFrontRunners} from "../src/modules/FrontRunnerProtection.sol";
import {LinearBondingCurve} from "../src/modules/LinearBondingCurve.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrowdsaleTest is Test {
    LinearBondingCurve bondingCurve;
    PreventFrontRunners frontRunnerPreventer;
    Crowdsale crowdsale;
    ERC20 token;
    
    address admin;

    function setUp() public {
        token = new ERC20("Mock Token", "MTK");
        bondingCurve = new LinearBondingCurve();
        frontRunnerPreventer = new PreventFrontRunners();

        crowdsale = new Crowdsale(
            payable(address(this)),
            IERC20(token)
        );
    }

    function testDeployment() public {
        assertEq(address(crowdsale.owner()), address(this)); // Assuming the deploying address is the owner
    }

    function testReceive() public {
        uint256 initialBalance = address(crowdsale).balance;
        payable(address(crowdsale)).transfer(1 ether); // Sending 1 ether to the contract
        uint256 finalBalance = address(crowdsale).balance;
        assertEq(finalBalance, initialBalance + 1 ether); // Testing ether was received
    }

}
