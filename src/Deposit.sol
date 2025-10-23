// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Deposit {
    using SafeERC20 for IERC20;

    /// Errors ///
    error Deposit__ZeroAddress();
    error Deposit__ZeroAmount();
    error Deposit__TokenNotAllowed(address tokenAddress);

    /// State Variables ///
    mapping(address user => mapping(address token => uint256 amount)) private s_userDeposited;
    mapping(address user => uint256 amount) private s_userFee;
    mapping(address token => bool isAllowed) private s_allowedTokens;

    /// Modifiers ///
    modifier checkZeroAddress(address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert Deposit__ZeroAddress();
        }
        _;
    }

    modifier checkZeroAmount(uint256 _amount) {
        if (_amount == 0) {
            revert Deposit__ZeroAmount();
        }
        _;
    }

    modifier checkAllowedTokens(address _tokenAddress) {
        if (!s_allowedTokens[_tokenAddress]) {
            revert Deposit__TokenNotAllowed(_tokenAddress);
        }
        _;
    }

    /// Functions ///

    /**
     * @notice Deposit function called by other contracts to deposit tokens to Deposit contract
     * @param _tokenAddress address of the token
     * @param _amount of tokens to deposit
     */
    function deposit(address _tokenAddress, uint256 _amount)
        external
        payable
        checkZeroAddress(_tokenAddress)
        checkZeroAmount(_amount)
        checkAllowedTokens(_tokenAddress)
    {
        s_userFee[msg.sender] += msg.value;
        _deposit(_tokenAddress, _amount);
    }

    /**
     * @notice Internal deposit function called by deposit function
     * @param _tokenAddress address of the token
     * @param _amount of tokens to deposit
     */
    function _deposit(address _tokenAddress, uint256 _amount) internal {
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        s_userDeposited[msg.sender][_tokenAddress] += _amount;
    }

    /**
     * @notice User can redeem the amount of token deposited from the contract
     * @param _token to redeeem
     * @param _amount to redeem
     */
    function redeem(address _token, uint256 _amount)
        external
        checkZeroAddress(_token)
        checkZeroAmount(_amount)
        checkAllowedTokens(_token)
    {
        s_userDeposited[msg.sender][_token] -= _amount;
        IERC20(msg.sender).safeTransfer(msg.sender, _amount);
    }

    /// Getter Functions ///

    /**
     * @notice User can get information on how much amount of particular token they have deposited
     * @param _token address of the token
     * @return Amount of token deposited
     */
    function getUserTokenValue(address _token) external view returns (uint256) {
        return s_userDeposited[msg.sender][_token];
    }

    /**
     * @notice Returns how much user has paid in fees
     * @return uint256 
     */
    function getUserFeeValue() external view returns (uint256) {
        return s_userFee[msg.sender];
    }

    /**
     * Returns a bool if the token is allowed or not
     * @param _tokenAddress address of the token
     * @return bool
     */
    function getIsAllowedTokens(address _tokenAddress) external view returns (bool) {
        return s_allowedTokens[_tokenAddress];
    }

    /// Setter Functions ///

    /**
     * Sets a particular token to be allowed or restriced
     * @param _tokenAddress address of the token
     * @param _isAllowed set if the token is allowed or restricted
     */
    function setAllowedTokens(address _tokenAddress, bool _isAllowed) external {
        s_allowedTokens[_tokenAddress] = _isAllowed;
    }
}
