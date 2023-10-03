// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OpenZeppelin Contracts
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC777.sol";
import "@openzeppelin/contracts/interfaces/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ERC1363 Interfaces
import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import {IERC1363Receiver} from "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import {IERC1363Spender} from "erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol";

// Custom LinearBondingCurve and PreventFrontRunners modules
import {LinearBondingCurve} from "./modules/LinearBondingCurve.sol";
import {PreventFrontRunners} from "./modules/PreventFrontRunners.sol";

abstract contract Crowdsale is 
    Context, 
    ReentrancyGuard, 
    IERC777Recipient, 
    IERC777Sender,
    Ownable,
    ERC1363,
    LinearBondingCurve,
    PreventFrontRunners,
    IERC1363Receiver,
    IERC1363Spender
{

  // The token being sold
  IERC20 public token;
  // Address where funds are collected
  address payable public wallet;
  // How many token units a buyer gets per wei
  uint256 public rate;
  // Amount of wei raised
  uint256 public weiRaised;
  // keeps track of total tokens sold
  uint256 public totalTokensSold;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address payable _wallet, IERC20 _token) {
    require(_rate > 0, "Crowdsale rate is 0");
    require(_wallet != address(0), "Crowdsale wallet is the zero address");
    require(address(_token) != address(0), "Crowdsale: token is the zero address");

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  function setMaxGasPriceAllowed(uint256 gasPrice) external onlyOwner {
    setMaxGasPrice(gasPrice);
  }

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  receive() external payable nonReentrant {
    enforceNormalGasPrice();
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_msgSender(), weiAmount);

    // tokenToEthBuy is a function in LinearBondingCurve that returns the cost in ETH for buying tokens
    uint256 tokens = tokenToEthBuy(totalSupply(), weiAmount);
    weiRaised += weiAmount;

    _processPurchase(_msgSender(), tokens);
    emit TokensPurchased(_msgSender(), _msgSender(), weiAmount, tokens);

    _updatePurchasingState(_msgSender(), weiAmount);
    _forwardFunds();
    _postValidatePurchase(_msgSender(), weiAmount);
    }

    function tokensReceived(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes calldata userData,
      bytes calldata operatorData
  ) external 
    override 
    prevent0TokenSale(amount) 
    onlyThisContractIsReceiver 
  {
      require(msg.sender == address(token), "Simple777Recipient: Invalid token");
      
      // Convert to natural form if needed
    uint256 naturalAmount = amount / 10 ** uint256(token.decimals());

    // Process the sale
    processSale(operator, from, naturalAmount, userData);
  }
  
  function onTransferReceived(
    address spender,
    address sender, 
    uint256 amount,
    bytes calldata data
  )
    external
    override
    prevent0TokenSale(amount)
    onlyThisContractIsReceiver
    returns (bytes4)
  {
   // Convert to natural form if needed
   uint256 naturalAmount = amount / 10 ** uint256(token.decimals());

   // Process the sale
   processSale(operator, from, naturalAmount, data);

   return IERC1363Receiver.onTransferReceived.selector;
  }
  
  /**
   * Sell/Burn Project Token and return ETH (with current price)
   * Spend functionality of ERC20
   */
  function onApprovalReceived(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    prevent0TokenSale(amount)
    onlyThisContractIsReceiver
    returns (bytes4)
  {
    require(msg.sender == address(token), "Invalid token");
    require(IERC20(token).transferFrom(sender, address(this), amount), "Transfer failed");
    processSale(sender, address(0), amount, data);
    return IERC1363Spender.onApprovalReceived.selector;
  }
  

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return weiRaised;
    }


  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
  {
    require(_beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
    require(_weiAmount != 0, "Crowdsale: weiAmount is 0");
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view 
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
)
    internal virtual
{
    // Convert to smallest unit
    uint256 smallestUnitAmount = _tokenAmount * 10 ** uint256(token.decimals()); 

    // Transfer tokens and check for failure
    require(token.transfer(_beneficiary, smallestUnitAmount), "Token transfer failed");

    // Update total tokens sold
    totalTokensSold += smallestUnitAmount;
}



  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal virtual
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function amountOfTokenEthCanBuy(
    uint256 _weiAmount
) external view returns (uint256) {
    rate = howManyTokenEthCanBuy(totalSupply(), _weiAmount);
    return rate;
}

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function requiredEthToBuyToken(
    uint256 tokenToBuy
) external view returns (uint256) {
    return tokenToEthBuy(totalSupply(), tokenToBuy);
}



/** ------------------------------------------- Modifiers -------------------------------------------------- */

modifier onlyThisContractIsReceiver() {
    require(
        msg.sender == address(this),
        "Only this contract can receive tokens"
    );
    _;
}

modifier prevent0TokenSale(uint256 amount) {
    require(amount > 0, "can not sell 0 token");
    _;
}


 }