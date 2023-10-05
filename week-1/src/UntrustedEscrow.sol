// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    IERC20 public token;

    event DepositMade(address indexed depositor, address indexed recipient, uint256 amount);
    event WithdrawalUnlockStarted(address indexed recipient, uint256 endTime, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 withdrawalTime, uint256 amount);

    mapping(address => uint256) private _deposits;
    mapping(address => uint256) private _unlockTime;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function depositsOf(address account) public view returns (uint256) {
        return _deposits[account];
    }

    function deposit(address recipient, uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        _deposits[recipient] += amount;
        _unlockTime[recipient] = block.timestamp + 259200;  // 3 days in seconds
        emit DepositMade(msg.sender, recipient, amount);
        emit WithdrawalUnlockStarted(recipient, _unlockTime[recipient], amount);
    }

    function withdraw(uint256 amount) public {
        require(block.timestamp >= _unlockTime[msg.sender], "Withdrawal is locked");
        require(amount <= _deposits[msg.sender], "Insufficient balance available");
        require(token.transfer(msg.sender, amount), "Transfer failed");

        _deposits[msg.sender] -= amount;
        emit Withdrawn(msg.sender, block.timestamp, amount);
    }
}
