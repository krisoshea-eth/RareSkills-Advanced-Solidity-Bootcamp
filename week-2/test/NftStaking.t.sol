// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RoyaltyNFT} from "../src/RoyaltyNFT.sol";
import {StakingRewardToken} from "../src/StakingRewardToken.sol";
import {NftStaking} from "../src/NftStaking.sol";

contract NftStakingTest is Test {
    RoyaltyNFT public royaltyNFT;
    StakingRewardToken public stakingRewardToken;
    NftStaking public nftStaking;
    address constant ARTIST_ADDRESS = address(0x123);
    bytes32 constant MERKLE_ROOT = keccak256("merkleRoot");

    function setUp() public {
        royaltyNFT = new RoyaltyNFT(MERKLE_ROOT, address(this), "https://metadataURI/", ARTIST_ADDRESS);
        stakingRewardToken = new StakingRewardToken(address(this));
        nftStaking = new NftStaking(address(royaltyNFT), address(stakingRewardToken));
    }

    function test_stakeNFT() public {
        uint256 tokenId = 1;
        uint256 cost = 2 ether;
        royaltyNFT.mint{value: cost}(tokenId, cost);
        nftStaking.stakeNFT(tokenId);
        assertEq(nftStaking.NftOwner(tokenId), address(this));
    }

    function test_unstakeNFT() public {
        uint256 tokenId = 1;
        nftStaking.unstakeNFT(tokenId);
        assertEq(royaltyNFT.ownerOf(tokenId), address(this));
    }

    function test_claimReward() public {
        uint256 tokenId = 1;
        nftStaking.claimReward(tokenId);
        uint256 reward = nftStaking.calculateAvailableReward(tokenId);
        assertEq(stakingRewardToken.balanceOf(address(this)), reward);
    }

    function testFail_stakeNFT_nonExistentToken() public {
        uint256 tokenId = 999;  // Assuming this token has not been minted
        nftStaking.stakeNFT(tokenId);  // Should fail
    }

    function testFail_unstakeNFT_notOwner() public {
        uint256 tokenId = 1;
        nftStaking.unstakeNFT(tokenId);  // Assuming msg.sender is not the owner of the token. Should fail.
    }

    function testFail_claimReward_notOwner() public {
        uint256 tokenId = 1;
        nftStaking.claimReward(tokenId);  // Assuming msg.sender is not the owner of the token. Should fail.
    }

    function testFail_claimReward_stakedLessThanOneDay() public {
        uint256 tokenId = 1;
        nftStaking.claimReward(tokenId);  // Assuming the token has been staked for less than 1 day. Should fail.
    }
}
