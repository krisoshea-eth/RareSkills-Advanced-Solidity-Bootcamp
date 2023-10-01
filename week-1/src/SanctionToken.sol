// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.3/access/AccessControl.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SANCTION_ROLE = keccak256("SANCTION_ROLE");
    address[] public bannedList;

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(SANCTION_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function ban(address bannedAddress) public onlyRole(SANCTION_ROLE) {
        bannedList.push(bannedAddress);
    }

    function isBanned(address user) public view returns (bool) {
        for (uint256 i = 0; i < bannedList.length; i++) {
            if (bannedList[i] == user) {
                return true;
            }
        }
        return false;
    }

    function transferAllow(address recipient, uint256 amount) external returns (bool) {
        require(!isBanned(msg.sender), "Sender is banned");
        require(!isBanned(recipient), "Recipient banned");
        _transfer(msg.sender, recipient, amount);
        return true;
    }
}
