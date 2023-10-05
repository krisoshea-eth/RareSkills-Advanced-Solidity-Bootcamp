// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @title Possible solution to mitigate front runners
 * @notice Bonding curves enable front-running attacks,
 *  where traders exploit foreknowledge of pending orders to place their own orders with higher gas,
 *  cutting ahead of the original order for profits.
 */

contract PreventFrontRunners is AccessControl, ReentrancyGuard {
    /**
     * ------------------------------------ State variables ------------------------------------
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public maxGasPrice = 100 gwei; // Adjustable value

    event MaxGasPriceChanged(uint256 newMaxGasPrice, string etherUnit);
    event GasPriceEnforced(address indexed user, uint256 gasPrice);

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * ------------------------------------ External functions ------------------------------------
     */

    /**
     * try to mitigate front-running with an explicit cap on {maxGasPrice} traders are allowed to offer gas price.
     * @param gasPrice the cap for the normal gas price
     */
    function setMaxGasPrice(uint256 gasPrice) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(gasPrice >= 1 gwei, "Gas price too low");
        maxGasPrice = gasPrice;
        emit MaxGasPriceChanged(gasPrice, "wei");
    }

    /**
     * ------------------------------------ Internal functions ------------------------------------
     */

    /**
     * Traders are limited to set their explicit gas price below the {maxGasPrice}
     */
    function enforceNormalGasPrice() internal view {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price!");
        emit GasPriceEnforced(msg.sender, tx.gasprice);
    }
}
