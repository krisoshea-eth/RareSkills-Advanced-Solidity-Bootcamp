// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    

    IERC20 public token;

    event DepositMade(address indexed depositor, address indexed recipient, uint256 amount);
    event WithdrawalUnlockStarted(address indexed recipient, uint256 endTime, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 withdrawalTime, uint256 amount);

    mapping(address => uint256) private _payeeDepositedBalance;
    mapping(address => mapping(uint256 => uint256)) private _recipientAvailableBalance;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _payeeDepositedBalance[payee];
    }

    function deposit(address recipient, uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        _payeeDepositedBalance[msg.sender] += amount;
        uint256 endTime = _startWithdrawalUnlock(recipient, amount);

        emit DepositMade(msg.sender, recipient, amount);
        emit WithdrawalUnlockStarted(recipient, endTime, amount);
    }

    function _startWithdrawalUnlock(address recipient, uint256 amount) private returns (uint256) {
        uint256 endTime = block.timestamp + 259200; // 3 days time in seconds
        _recipientAvailableBalance[recipient][endTime] += amount;
        return endTime;
    }

    function withdraw(uint256 amount, uint256 endTime) public {
        require(block.timestamp >= endTime, "Withdrawal is locked");
        require(amount <= _recipientAvailableBalance[msg.sender][endTime], "Insufficient balance available");
        require(token.transfer(msg.sender, amount), "Transfer failed");

        _recipientAvailableBalance[msg.sender][endTime] -= amount;

        emit Withdrawn(msg.sender, block.timestamp, amount);
    }
}
