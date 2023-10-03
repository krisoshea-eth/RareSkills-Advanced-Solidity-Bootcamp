// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SanctionToken is ERC20, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SANCTION_ROLE = keccak256("SANCTION_ROLE");
    
    mapping(address => bool) public isBanned;

    constructor() ERC20("SanctionToken", "MTK") ERC20Permit("SanctionToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(SANCTION_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function ban(address bannedAddress) public onlyRole(SANCTION_ROLE) {
        isBanned[bannedAddress] = true;
    }

    function unban(address unbannedAddress) public onlyRole(SANCTION_ROLE) {
        isBanned[unbannedAddress] = false;
    }

    function isBanned(address user) public view returns (bool) {
        for (uint256 i = 0; i < bannedList.length; i++) {
            if (bannedList[i] == user) {
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!isBanned[from], "Sender is banned");
        require(!isBanned[to], "Recipient is banned");
        super._beforeTokenTransfer(from, to, amount);
    }
}
