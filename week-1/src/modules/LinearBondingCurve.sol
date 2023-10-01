// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "hardhat/console.sol";

contract LinearBondingCurve {
    /**
     * ------------------------------------ State variables ------------------------------------
     */

    uint256 public constant INITIAL_PRICE = 1 ether; // The initial price of tokens in ETH (e.g., 0.001 ETH)
    uint256 public constant INITIAL_SUPPLY = 0; // The initial supply of tokens set to 0.
    uint256 public constant PRICE_SLOPE = 1 ether; // The price increase per token sold - fixed at 1 ether.

    uint256 private constant DECIMAL = 1000; // 3 fixed decimal points
    uint256 private constant SCALE = 1e18;

    /**
     * ------------------------------------ Constructor ------------------------------------
     */
    constructor() {}

    /**
     * ------------------------------------ Internal functions ------------------------------------
     */

    /**
     * Calculate how much does it cost in ETH to buy a certain amount of token
     *  the formula to calculate it: Linear Bonding curve  y = x
     *      ((new_token_amount_to_buy / 2) * (2 * _current_token_supply + new_token_amount_to_buy + 1))
     * @param currentTokenSupplyInWei totalSupply of the token
     * @param newTokenAmountToBuy the amount of new token to mint
     *
     * @return finalCost the require amount of ETH to buy {newTokenAmountToBuy} right now!
     */
    function tokenToEthBuy(uint256 currentTokenSupplyInWei, uint256 newTokenAmountToBuy)
        internal
        pure
        returns (uint256 finalCost)
    {
        uint256 _tokenSupplyInEther = currentTokenSupplyInWei / SCALE;

        uint256 _a = ((newTokenAmountToBuy * DECIMAL) / 2);
        uint256 _b = (2 * _tokenSupplyInEther);
        uint256 _c = (newTokenAmountToBuy + 1);

        finalCost = ((_a * (_b + _c)) / DECIMAL) * SCALE;
    }

    /**
     * Calculate how many token with the {depositedEthAmount} can be bought in current Curve status
     * @param currentSupplyInWei the current token totalSupply() in WEI
     * @param depositedEthAmount the amount of deposited ETH
     *
     * @notice this implementation is not scalable and can only be used to buy at most 14k token.
     * @custom:todo Replace it with a scalable advanced math formula
     *
     * @return tokenCount the amount of token that can be bought with the {depositedEthAmount} ETH
     */
    function howManyTokenEthCanBuy(uint256 currentSupplyInWei, uint256 depositedEthAmount)
        internal
        pure
        returns (uint256 tokenCount)
    {
        for (uint256 i = 0;; i++) {
            uint256 _cost = tokenToEthBuy(currentSupplyInWei, i);
            if (_cost >= depositedEthAmount) {
                return i;
            }
        }
    }

    /**
     * calculate the amount of Reserve ($ETH) to return for token sale
     * @param currentTokenSupplyInWei the current token supply
     * @param tokenAmountToSellInWei the amount of token to sell
     *
     * @return ethReturnValue the amount of ETH to return for selling {tokenAmountToSellInWei} token
     */
    function tokenToEthSell(uint256 currentTokenSupplyInWei, uint256 tokenAmountToSellInWei)
        internal
        pure
        returns (uint256 ethReturnValue)
    {
        uint256 _amountToSell = tokenAmountToSellInWei / SCALE;
        uint256 _currentSupply = currentTokenSupplyInWei / SCALE;

        uint256 _newTokenSupplyAfterTheSale = _currentSupply - _amountToSell;

        ethReturnValue = tokenToEthBuy(_newTokenSupplyAfterTheSale, _amountToSell);
    }
}
