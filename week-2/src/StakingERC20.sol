// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts@4.3.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.3.2/access/Ownable2Step.sol";
import "@openzeppelin/contracts@4.3.2/access/AccessControl.sol";

contract StakingRewardToken is ERC20, Ownable2Step, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address initialOwner) ERC20("StakingRewardToken", "SRT") Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid address");
        _setupRole(MINTER_ROLE, initialOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, initialOwner);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(to != address(0), "Invalid address");
        _mint(to, amount);
    }
}
