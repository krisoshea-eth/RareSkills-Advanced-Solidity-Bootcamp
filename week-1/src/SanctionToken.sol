// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract SanctionToken is ERC20, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SANCTION_ROLE = keccak256("SANCTION_ROLE");

    mapping(address => bool) public isBanned;

    event AddressBanned(address indexed bannedAddress);
    event AddressUnbanned(address indexed unbannedAddress);
    event TokensMinted(address indexed to, uint256 amount);

    constructor() ERC20("SanctionToken", "MTK") ERC20Permit("SanctionToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(SANCTION_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function ban(address bannedAddress) public onlyRole(SANCTION_ROLE) {
        isBanned[bannedAddress] = true;
        emit AddressBanned(bannedAddress);
    }

    function unban(address unbannedAddress) public onlyRole(SANCTION_ROLE) {
        isBanned[unbannedAddress] = false;
        emit AddressUnbanned(unbannedAddress);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!isBanned[from], "Sender is banned");
        require(!isBanned[to], "Recipient is banned");
        super._beforeTokenTransfer(from, to, amount);
    }
}
