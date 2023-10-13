// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts@5.0.0/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts@5.0.0/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@5.0.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@5.0.0/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts@5.0.0/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts@5.0.0/contracts/utils/ReentrancyGuard.sol";
import "./StakingERC20.sol";

contract NftStaking is ERC721Holder, ReentrancyGuard {
    StakingRewardToken public stakingRewardToken;
    IERC721 public RoyaltyNFT;
    uint256 public DAILY_EMISSION_AMOUNT = 10 * 10 ** 18;

    mapping(uint256 => address) public NftOwner;
    mapping(uint256 => uint256) public timeStakeWasInitiated;

    event NFTStaked(uint256 indexed tokenId, address indexed staker);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker);
    event RewardClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);

    constructor(address _RoyaltyNFT, address _stakingRewardToken) {
        require(_RoyaltyNFT != address(0) && _stakingRewardToken != address(0), "Invalid addresses");
        RoyaltyNFT = IERC721(_RoyaltyNFT);
        stakingRewardToken = StakingRewardToken(_stakingRewardToken);
    }

    function stakeNFT(uint256 tokenId) external {
        require(NftOwner[tokenId] == address(0), "Token already staked");
        NftOwner[tokenId] = msg.sender;
        timeStakeWasInitiated[tokenId] = block.timestamp;
        RoyaltyNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTStaked(tokenId, msg.sender);
    }

    function unstakeNFT(uint256 tokenId) external nonReentrant {
        require(NftOwner[tokenId] == msg.sender, "You are not the NFT owner");
        require(NftOwner[tokenId] != address(0), "Token not staked");

        delete NftOwner[tokenId];
        delete timeStakeWasInitiated[tokenId];

        claimReward(tokenId);
        RoyaltyNFT.safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(tokenId, msg.sender);
    }

    function claimReward(uint256 tokenId) public nonReentrant {
        require(NftOwner[tokenId] == msg.sender, "You are not the NFT owner");

        uint256 reward = calculateAvailableReward(tokenId);

        // Reset the stake time to the current timestamp
        timeStakeWasInitiated[tokenId] = block.timestamp;

        StakingRewardToken.mint(msg.sender, reward);
        emit RewardClaimed(tokenId, msg.sender, reward);
    }

    function calculateAvailableReward(uint256 tokenId) internal view returns (uint256) {
        uint256 availableRewardAmount =
            ((block.timestamp - timeStakeWasInitiated[tokenId]) / 1 days) * DAILY_EMISSION_AMOUNT;
        return availableRewardAmount;
    }
}
