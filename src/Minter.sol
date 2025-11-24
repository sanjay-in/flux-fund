// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "./DSC.sol";
import {IRouter} from "./interface/IRouter.sol";

contract Minter is Ownable {
    using SafeERC20 for IERC20;

    /// Errors ///
    error Minter__ZeroAddress();
    error Minter__ZeroAmount();
    error Minter__CallerIsNotRouterContract();

    /// State Variables ///
    DecentralizedStableCoin private immutable i_dsc;

    address private s_mainRouter;

    mapping(address user => uint256 amount) private s_minted;
    mapping(address user => uint256 fee) private s_userFee;

    /// Events ///
    event DSCMinted(address indexed _user, uint256 indexed _amount);
    event DSCBurned(address indexed _user, uint256 indexed _amount);

    constructor(address _mainRouter) Ownable(msg.sender) {
        i_dsc = new DecentralizedStableCoin("DecentralizedStableCoin", "DSC");
        s_mainRouter = _mainRouter;
    }

    receive() external payable {
        s_userFee[msg.sender] += msg.value;
    }

    /// Modifiers ///
    modifier checkZeroAddress(address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert Minter__ZeroAddress();
        }
        _;
    }

    modifier checkZeroAmount(uint256 _amount) {
        if (_amount == 0) {
            revert Minter__ZeroAmount();
        }
        _;
    }

    modifier onlyMainRouter(address _mainRouter) {
        if (_mainRouter != s_mainRouter) {
            revert Minter__CallerIsNotRouterContract();
        }
        _;
    }

    /// Functions ///

    /** 
     * @notice Calls internal mint function
     * @param _to who wants to mint the DSC to
     * @param _amount of DSC to mint
     */
    function mint(address _to, uint256 _amount) external checkZeroAddress(_to) checkZeroAmount(_amount) onlyMainRouter(msg.sender) {
        _mint(_to, _amount);
    }

    /**
     * @notice Mint function updates the minted value and mints DSC to the receiver
     * @param _to who wants to mint the DSC to
     * @param _amount of DSC to mint
     */
    function _mint(address _to, uint256 _amount) internal {
        s_minted[_to] += _amount;
        i_dsc.mint(_to, _amount);
        emit DSCMinted(_to, _amount);
    }

    /**
     * @notice Updates the user fee and calls internal burn function
     * @param _user token to burn
     * @param _amount of DSC to burn
     */
    function burn(address _user, uint256 _amount) external payable checkZeroAddress(_user) checkZeroAmount(_amount) {
        s_userFee[msg.sender] += _amount;
        _burn(_user, _amount);
    }

    /**
     * @notice Transfers the token to Minter contract from the user and burns them
     * @param _user token to burn
     * @param _amount of DSC to burn
     */
    function _burn(address _user, uint256 _amount) internal {
        s_minted[_user] -= _amount;
        IERC20(address(i_dsc)).safeTransferFrom(_user, address(this), _amount);
        i_dsc.burn(_amount);
        emit DSCBurned(_user, _amount);
    }

    /**
     * @notice Liquidate a particular user's collateral who violates the health factor
     * Checks for zero address of token and user and checks zero amount
     * @param _userToLiquidate address of the user to liquidate
     * @param _receiver address of the Depositor contract
     * @param _token address of the token
     * @param _amount of debt to cover
     */
    function liquidate(address _userToLiquidate, address _receiver, address _token, uint256 _amount) 
        external 
        payable 
        checkZeroAmount(_amount) 
        checkZeroAddress(_token)
        checkZeroAddress(_userToLiquidate) 
    {
        s_userFee[msg.sender] += msg.value;
        _liquidate(_userToLiquidate, _receiver, msg.sender, _token, _amount);
    }

    /**
     * @notice Internal function called by liquidate function
     * It burns the amount the user wants to cover and calls the liquidate function on the main router
     * @param _userToLiquidate address of the user to liquidate
     * @param _receiver address of the Depositor contract
     * @param _sender address of the sender who wants to liquidate a user
     * @param _token address of the token
     * @param _amount of debt to cover
     */
    function _liquidate(address _userToLiquidate, address _receiver, address _sender, address _token, uint256 _amount) internal {
        _burn(_sender, _amount);
        IRouter(s_mainRouter).liquidate(_userToLiquidate, _receiver, _token, _amount, _sender);
    }

    /// Getter Functions ///

    /**
     * @notice Gets the amount of DSC the user has minted
     * @param _user address of the user who minted tokens
     */
    function getMintedAmountForUser(address _user) external view returns(uint256) {
        return s_minted[_user];
    }

    /**
     * @notice Gets the total user fee of user on the contract
     * @param _user address of the user to minted or burned tokens
     */
    function getUserFee(address _user) external view returns(uint256) {
        return s_userFee[_user];
    }

    /**
     * @notice Gets DSC contract
     * @return DecentralizedStableCoin
     */
    function getDecentralizedStableCoin() external view returns (DecentralizedStableCoin) {
        return i_dsc;
    }


    /// Setter Functions ///

    /**
     * Updates the main router address
     * @param _mainRouter address of the new main router
     */
    function setMainRouter(address _mainRouter) external onlyOwner {
        s_mainRouter = _mainRouter;
    }
}