// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract LinearBondingCurve is AccessControl {
    // State variables
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private _initialPrice; // Initial price of tokens in ETH
    uint256 private _priceSlope; // The price increase per token sold

    // Constants with added comments for clarity
    uint256 private constant DECIMAL = 1000; // 3 fixed decimal points for precision
    uint256 private constant SCALE = 1e18; // Scaling factor for token amounts

    // Events
    event TokensPurchased(
        uint256 indexed currentTokenSupplyInWei, uint256 indexed newTokenAmountToBuy, uint256 finalCost
    );
    event TokensSold(
        uint256 indexed currentTokenSupplyInWei, uint256 indexed tokenAmountToSellInWei, uint256 ethReturnValue
    );
    event ParametersUpdated(uint256 newInitialPrice, uint256 newPriceSlope);

    // Constructor
    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _initialPrice = 1 ether; // Default initial price
        _priceSlope = 1 ether; // Default price slope
    }

    // External functions to update parameters, only accessible by admin
    function updateParameters(uint256 newInitialPrice, uint256 newPriceSlope) external onlyRole(ADMIN_ROLE) {
        _initialPrice = newInitialPrice;
        _priceSlope = newPriceSlope;
        emit ParametersUpdated(newInitialPrice, newPriceSlope);
    }

    // Getter functions for state variables
    function initialPrice() public view returns (uint256) {
        return _initialPrice;
    }

    function priceSlope() public view returns (uint256) {
        return _priceSlope;
    }

    // Internal functions

    // Calculate the cost in ETH for buying a certain amount of tokens
    // Uses the formula: ((newTokenAmountToBuy / 2) * (2 * currentTokenSupplyInWei + newTokenAmountToBuy + 1))
    function tokenToEthBuy(uint256 currentTokenSupplyInWei, uint256 newTokenAmountToBuy) internal pure returns (uint256) {
        require(newTokenAmountToBuy > 0, "The amount of tokens to buy must be greater than zero");
        uint256 tokenSupplyInEther = currentTokenSupplyInWei / SCALE;

        uint256 a = (newTokenAmountToBuy * DECIMAL) / 2;
        uint256 b = tokenSupplyInEther * 2;
        uint256 c = newTokenAmountToBuy + 1;

        uint256 finalCost = ((a * (b + c)) / DECIMAL) * SCALE;

        return finalCost;
    }

    function testTokenToEthBuy(uint256 currentTokenSupplyInWei, uint256 newTokenAmountToBuy) public pure returns (uint256) {
        return tokenToEthBuy(currentTokenSupplyInWei, newTokenAmountToBuy);
    }
    

    // Calculate the number of tokens that can be bought with a given amount of ETH
    function howManyTokenEthCanBuy(uint256 currentSupplyInWei, uint256 depositedEthAmount) internal pure returns (uint256) {
        uint256 currentSupplyInEther = currentSupplyInWei / SCALE;
        uint256 depositedEthInEther = depositedEthAmount / SCALE;

        uint256 discriminant = Math.sqrt((4 * currentSupplyInEther * currentSupplyInEther) + (8 * depositedEthInEther));
        uint256 newTokenAmountToBuy = (discriminant - (2 * currentSupplyInEther)) / 2;

        return newTokenAmountToBuy;
    }

    function testHowManyTokenEthCanBuy(uint256 currentSupplyInWei, uint256 depositedEthAmount) public pure returns (uint256) {
        return howManyTokenEthCanBuy(currentSupplyInWei, depositedEthAmount);
    }

    // Calculate the amount of ETH to return for selling a certain amount of tokens
    function tokenToEthSell(uint256 currentTokenSupplyInWei, uint256 tokenAmountToSellInWei) internal pure returns (uint256) {
        require(tokenAmountToSellInWei > 0, "The amount of tokens to sell must be greater than zero");

        uint256 amountToSell = tokenAmountToSellInWei / SCALE;
        uint256 currentSupply = currentTokenSupplyInWei / SCALE;

        uint256 newTokenSupplyAfterTheSale = currentSupply - amountToSell;

        uint256 ethReturnValue = tokenToEthBuy(newTokenSupplyAfterTheSale, amountToSell);

        return ethReturnValue;
    }

    function testTokenToEthSell(uint256 currentTokenSupplyInWei, uint256 newTokenAmountToBuy) public pure returns (uint256) {
        return tokenToEthSell(currentTokenSupplyInWei, newTokenAmountToBuy);
    }
}
