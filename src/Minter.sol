// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DecentralizedStableCoin} from "./DSC.sol";

contract Minter {
    using SafeERC20 for IERC20;

    /// Errors ///
    error Minter__ZeroAddress();
    error Minter__ZeroAmount();

    /// State Variables ///
    DecentralizedStableCoin private immutable i_dsc;

    mapping(address user => uint256 amount) private s_minted;
    mapping(address user => uint256 fee) private s_userFee;

    /// Events ///
    event DSCMinted(address indexed _user, uint256 indexed _amount);
    event DSCBurned(address indexed _user, uint256 indexed _amount);

    constructor() {
        i_dsc = new DecentralizedStableCoin("DecentralizedStableCoin", "DSC");
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

    /// Functions ///

    /** 
     * @notice Calls internal mint function
     * @param _receiver who wants to mint the DSC to
     * @param _amount of DSC to mint
     */
    function mint(address _receiver, uint256 _amount) external checkZeroAddress(_receiver) checkZeroAmount(_amount) {
        _mint(_receiver, _amount);
    }

    /**
     * @notice Mint function updates the minted value and mints DSC to the receiver
     * @param _receiver who wants to mint the DSC to
     * @param _amount of DSC to mint
     */
    function _mint(address _receiver, uint256 _amount) internal {
        s_minted[_receiver] += _amount;
        i_dsc.mint(_receiver, _amount);
        emit DSCMinted(_receiver, _amount);
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
}