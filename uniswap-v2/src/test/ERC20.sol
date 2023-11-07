// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/solady/src/tokens/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor(uint256 _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
