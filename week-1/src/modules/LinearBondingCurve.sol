// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LinearBondingCurve is AccessControl {
    // State variables
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private _initialPrice; // Initial price of tokens in ETH
    uint256 private _priceSlope; // The price increase per token sold

    // Constants with added comments for clarity
    uint256 private constant DECIMAL = 1000; // 3 fixed decimal points for precision
    uint256 private constant SCALE = 1e18; // Scaling factor for token amounts

    // Events
    event TokensPurchased(uint256 indexed currentTokenSupplyInWei, uint256 indexed newTokenAmountToBuy, uint256 finalCost);
    event TokensSold(uint256 indexed currentTokenSupplyInWei, uint256 indexed tokenAmountToSellInWei, uint256 ethReturnValue);
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
    function tokenToEthBuy(uint256 currentTokenSupplyInWei, uint256 newTokenAmountToBuy) internal returns (uint256) {
        require(newTokenAmountToBuy > 0, "The amount of tokens to buy must be greater than zero");
        uint256 tokenSupplyInEther = currentTokenSupplyInWei / SCALE;

        uint256 a = (newTokenAmountToBuy * DECIMAL) / 2;
        uint256 b = tokenSupplyInEther * 2;
        uint256 c = newTokenAmountToBuy + 1;

        uint256 finalCost = ((a * (b + c)) / DECIMAL) * SCALE;

        emit TokensPurchased(currentTokenSupplyInWei, newTokenAmountToBuy, finalCost);
        return finalCost;
    }

    // Calculate the number of tokens that can be bought with a given amount of ETH
    function howManyTokenEthCanBuy(uint256 currentSupplyInWei, uint256 depositedEthAmount) internal returns (uint256) {
        uint256 currentSupplyInEther = currentSupplyInWei / SCALE;
        uint256 depositedEthInEther = depositedEthAmount / SCALE;

        uint256 discriminant = sqrt((4 * currentSupplyInEther * currentSupplyInEther) + (8 * depositedEthInEther));
        uint256 newTokenAmountToBuy = (discriminant - (2 * currentSupplyInEther)) / 2;

        return newTokenAmountToBuy;
    }

    // Calculate the amount of ETH to return for selling a certain amount of tokens
    function tokenToEthSell(uint256 currentTokenSupplyInWei, uint256 tokenAmountToSellInWei) internal returns (uint256) {
        require(tokenAmountToSellInWei > 0, "The amount of tokens to sell must be greater than zero");

        uint256 amountToSell = tokenAmountToSellInWei / SCALE;
        uint256 currentSupply = currentTokenSupplyInWei / SCALE;

        uint256 newTokenSupplyAfterTheSale = currentSupply - amountToSell;

        uint256 ethReturnValue = tokenToEthBuy(newTokenSupplyAfterTheSale, amountToSell);

        emit TokensSold(currentTokenSupplyInWei, tokenAmountToSellInWei, ethReturnValue);
        return ethReturnValue;
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
