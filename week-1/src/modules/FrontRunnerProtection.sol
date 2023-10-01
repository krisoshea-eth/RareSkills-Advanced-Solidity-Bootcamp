// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Possible solution to mitigate front runners
 * @notice Bonding curves enable front-running attacks,
 *  where traders exploit foreknowledge of pending orders to place their own orders with higher gas,
 *  cutting ahead of the original order for profits.
 */
contract PreventFrontRunners {
    /**
     * ------------------------------------ State variables ------------------------------------
     */

    uint256 public maxGasPrice = 100 gwei; // Adjustable value

    /**
     * ------------------------------------ External functions ------------------------------------
     */

    /**
     * try to mitigate front-running with an explicit cap on {maxGasPrice} traders are allowed to offer gas price.
     * @param gasPrice the cap for the normal gas price
     */
    function setMaxGasPrice(uint256 gasPrice) internal {
        maxGasPrice = gasPrice;
    }

    /**
     * ------------------------------------ Internal functions ------------------------------------
     */

    /**
     * Traders are limited to set their explicit gas price below the {maxGasPrice}
     */
    function enforceNormalGasPrice() internal view {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price!");
    }
}
