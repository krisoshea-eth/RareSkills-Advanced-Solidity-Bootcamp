// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";

contract UniswapV2FlashSwap is IUniswapV2Callee {
    
    event Log(string message, uint value);

    funciton initiateFlashSwap(address _tokenBorrow, address _tokenDeposit, uint _amount) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, _tokenDeposit);
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // we need some data to trigger uniswapV2Call
        bytes memory data = abi.encode(_tokenBorrow, _amount);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data)
    }


    function uniswapV2Call(
        address sender, 
        uint amount0, 
        uint amount1, 
        bytes calldata data
        ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(sender == address(this), "!sender");

        (address tokenBorrow, uint amount) = abi.decode(data, (address, uint));

        // fee 0.3%
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount  + fee;

        emit Log("amount", amount);
        emit Log("amount0", amount0);
        emit Log("amount1", amount1);
        emit Log("fee", fee);
        emit Log("amount to repay", amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay)
        }
  }