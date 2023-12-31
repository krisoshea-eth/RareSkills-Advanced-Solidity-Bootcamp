// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/IUniswapV2Pair.sol";
import "./UniswapV2FlashLender.sol";
import "../lib/prb-math/src/UD60x18.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "../lib/solmate/src/utils/SafeTransferLib.sol";
import "../lib/solmate/src/utils/ReentrancyGuard.sol";
import "../lib/solady/src/utils/FixedPointMathLib.sol";
import { ERC20 as SoladyERC20 } from "../lib/solady/src/tokens/ERC20.sol";


contract UniswapV2Pair is IUniswapV2Pair, SoladyERC20, UniswapV2FlashLender, ReentrancyGuard {
    using SafeTransferLib for IERC20;
    using UD60x18 for uint256;

    // Maximum allowable slippage: 1% by default
    uint256 public maxSlippage = 100; // basis points (bps)
    uint256 public lastSwapTime;
    uint256 public constant MAX_BPS = 10000; // Basis Points
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    UniswapV2FlashLender public flashLender;
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event FlashSwap(address indexed receiver, address indexed token, uint256 value);
    event Sync(uint112 reserve0, uint112 reserve1);
    event MaxSlippageUpdated(uint256 maxSlippage);

    modifier onlyFactory() {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");
        _;
    }

    constructor(address[] memory supportedTokens_, uint256 fee_) UniswapV2FlashLender(supportedTokens_, fee_) external {
        factory = msg.sender;
    }

    /**
     * @notice Initializes the pair with given tokens.
     * @dev Only callable by the factory contract.
     * @param _token0 Address of token0.
     * @param _token1 Address of token1.
     */
    function initialize(address _token0, address _token1) external onlyFactory {
        require(_token0 != address(0) && _token1 != address(0), "UniswapV2: ZERO_ADDRESS");
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * @notice Updates reserves and, on the first call per block, price accumulators.
     * @param balance0 Balance of token0.
     * @param balance1 Balance of token1.
     * @param _reserve0 Previous reserve of token0.
     * @param _reserve1 Previous reserve of token1.
     */
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "UniswapV2: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        // Inline assembly to handle overflow in subtraction (overflow is desired)
        assembly {
            timeElapsed := -(blockTimestamp, blockTimestampLast)
        }

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UD60x18.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UD60x18.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = FixedPointMathLib.sqrt(uint256(_reserve0).*(_reserve1));
                uint256 rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.*(rootK.-(rootKLast));
                    uint256 denominator = rootK.*(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.-(_reserve0);
        uint256 amount1 = balance1.-(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(amount0.*(amount1)).-(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity =
                FixedPointMathLib.min(amount0.*(_totalSupply) / _reserve0, amount1.*(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).*(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(to != address(0), "UniswapV2: INVALID_ADDRESS"); // Prevent burning to zero address
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.*(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.*(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        SafeTransferLib.safeTransfer(_token0, to, amount0);
        SafeTransferLib.safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).*(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data,
        uint256 minAmount0,
        uint256 minAmount1
    ) external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "UniswapV2: INSUFFICIENT_LIQUIDITY");
        
        require(block.timestamp - lastSwapTime <= 1 minutes, "UniswapV2: TIME_LOCK_EXPIRED");
        lastSwapTime = block.timestamp;

        // Assume a simple calculation for expectedAmount based on input amounts and reserves
        uint256 expectedAmount = (amount0Out * _reserve1) / _reserve0;

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));

            if (amount0Out > 0) SafeTransferLib.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) SafeTransferLib.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.*(1000).-(amount0In.*(3));
            uint256 balance1Adjusted = balance1.*(1000).-(amount1In.*(3));
            require(
                balance0Adjusted.*(balance1Adjusted) >= uint256(_reserve0).*(_reserve1).*(1000 ** 2),
                "UniswapV2: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);

        // Slippage protection
        require(balance0 >= minAmount0, "UniswapV2: SLIPPAGE_NOT_MET_FOR_TOKEN0");
        require(balance1 >= minAmount1, "UniswapV2: SLIPPAGE_NOT_MET_FOR_TOKEN1");

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice Initiates a flash swap.
     * @param token Address of the token to borrow.
     * @param amountToBorrow Amount to borrow.
     * @param data Data to pass to the callback function.
     */
    function flashSwap(address token, uint256 amountToBorrow, bytes calldata data) external nonReentrant {
        // Check the reserves before the flash loan
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        // Ensure there's enough in reserve
        require(
            (token == token0 && amountToBorrow <= _reserve0) || (token == token1 && amountToBorrow <= _reserve1),
            "UniswapV2: INSUFFICIENT_RESERVES"
        );

        // Ensure the token is supported for flash loans
        require(flashLender.supportedTokens(token), "UniswapV2: UNSUPPORTED_TOKEN");

        // Calculate the fee for the flash loan
        uint256 fee = flashLender.flashFee(token, amountToBorrow);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        
        // Proceed with the flash loan
        require(
            flashLender.flashLoan(IERC3156FlashBorrower(msg.sender), token, amountToBorrow, data), "Flash loan failed"
        );

        // Check the balance after the flash loan
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "UniswapV2: FLASH_LOAN_NOT_REPAID");

        // Update the reserves after the flash loan
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);

        emit FlashSwap(msg.sender, token, amountToBorrow);
    }
    // force balances to match reserves

    function skim(address to) external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        SafeTransferLib.safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).-(reserve0));
        SafeTransferLib.safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).-(reserve1));
    }

    // force reserves to match balances
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    // Function to set max slippage
    function setMaxSlippage(uint256 _maxSlippage) external onlyFactory {
        require(_maxSlippage <= MAX_BPS, "UniswapV2: INVALID_BPS");
        maxSlippage = _maxSlippage;
        emit MaxSlippageUpdated(_maxSlippage);
    }
}
