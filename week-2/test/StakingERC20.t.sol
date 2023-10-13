// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakingRewardToken} from "../src/StakingRewardToken.sol";

contract StakingRewardTokenTest is Test {
    StakingRewardToken public stakingRewardToken;

    function setUp() public {
        stakingRewardToken = new StakingRewardToken(address(this));
    }

    function test_mint() public {
        stakingRewardToken.mint(address(this), 1000);
        assertEq(stakingRewardToken.balanceOf(address(this)), 1000);
    }

    function test_constructor() public {
        assertEq(stakingRewardToken.owner(), address(this));
        assertEq(stakingRewardToken.hasRole(stakingRewardToken.MINTER_ROLE(), address(this)), true);
        assertEq(stakingRewardToken.hasRole(stakingRewardToken.DEFAULT_ADMIN_ROLE(), address(this)), true);
    }

    function testFuzz_mint(uint256 amount) public {
        uint256 initialBalance = stakingRewardToken.balanceOf(address(this));
        stakingRewardToken.mint(address(this), amount);
        assertEq(stakingRewardToken.balanceOf(address(this)), initialBalance + amount);
    }
}
