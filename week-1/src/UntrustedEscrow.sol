// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Escrow is Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    event WithdrawalUnlockStarted(address indexed recipient, uint256 endTime, uint256 amount);
    event Withdrawn(address indexed recipient, uint256 withdrawalTime, uint256 amount);

    mapping(address => uint256) private _payeeDepositedBalance;
    mapping(address => mapping(uint256 => uint256)) private _recipientAvailableBalance;

    constructor ( address _token) {
        token = IERC20(_token);
}

function depositsOf(address payee) public view returns (uint256) {
        return _payeeDepositedBalance[payee];
    }

    function deposit(address recipient, uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount));

        _payeeDepositedBalance[msg.sender] = _payeeDepositedBalance[msg.sender].add(amount);
        uint256 endTime = _startWithdrawalUnlock(recipient, amount);
        emit withdrawalUnlockStarted(recipient, endTime, amount);
    }

    function _startWithdrawalUnlock(address recipient, uint256 amount) private returns (uint256 endTime) {
        uint256 endTime = block.timestamp.add(259200); // 3 days time
        _recipientAvailableBalance[recipient][endTime] = _recipientAvailableBalance[recipient][endTime].add(amount);
        return endTime;
    }

    function withdraw(address recipient, uint256 amount, uint256 endTime) public {
        require(block.timestamp >= endTime, "Withdrawal is locked");
        require(amount <= _recipientAvailableBalance[recipient][endTime], "Insufficent balance available");
        require(IERC20(token).transferFrom(address(this), recipient, amount));

        _payeeDepositedBalance[payee] = _payeeDepositedBalance[payee].sub(amount);
        _recipientAvailableBalance[recipient][endTime] = _recipientAvailableBalance[recipient][endTime.sub(amount)];

        emit Withdrawn(recipient, block.timestamp, amount);
    }
}
