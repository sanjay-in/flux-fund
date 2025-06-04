// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DSC} from "./DSC.sol";

contract Router {
    using SafeERC20 for IERC20;

    error Router__TokenNotSupported();
    error Router__AmountShouldBeMoreThanZero();

    address[] public s_allowedTokenAddresses[];
    DSC public immutable i_stableCoin; 

    mapping (address user => mapping (address tokenAdress => uint256 amount)) public s_userDepositAmount;
    mapping (address user => uint256 amount) public s_userMintedStableCoin;

    event CollateralDeposited(address indexed user, address indexed tokenAddress, uint256 amount);
    event MintedStableCoin(address indexed user, uint256 _amount);

    modifier onlyAllowedTokens(address _token) {
        if (!s_allowedTokenAddresses[_token]) {
            revert Router__TokenNotSupported();
        }
        _;
    }

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert Router__AmountShouldBeMoreThanZero();
        }
        _;
    }

    constructor(address[] _tokenAddresses, address _stableCoin) {
        s_allowedTokenAddresses = _tokenAddresses;
        i_stableCoin = DSC(_stableCoin);
    }

    /**
     * @notice This is an exernal function that deposits collateral and mints stable coin in one transaction
     * @param _tokenAddress address of the collateral
     * @param _amountToDeposit amount of collateral the user wants to deposit
     * @param _amountToMint amount of stablecoin user wishes to mint
     */
    function depositAndMintTokens(address _tokenAddress, uint256 _amountToDeposit, uint256 _amountToMint) external {
        depositCollateral(_tokenAddress, _amountToDeposit);
        mintTokens(_amountToMint);
    }

    /**
     * @notice Deposits collateral into the protocol
     * Checks if the collateral is supported
     * Checks if the collateral value is more than zero
     * @param _tokenAddress address of the collateral
     * @param _amount amount of collateral the user wants to deposit
     */
    function depositCollateral(address _tokenAddress, uint256 _amount) public onlyAllowedTokens(_tokenAddress) moreThanZero(_amount) {
        s_userDepositAmount[msg.sender][_tokenAddress] += _amount;
        emit CollateralDeposited(msg.sender, _tokenAddress, _amount);
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice This function mints stablecoins if you have enough health factor
     * @param _amountToMint amount of stablecoin user wish wishes to mint
     */
    function mintTokens(uint256 _amountToMint) public moreThanZero(_amountToMint) {
        s_userMintedStableCoin[msg.sender] += _amountToMint;
        emit MintedStableCoin(msg.sender, _amountToMint);
        // Check health factor
        i_stableCoin.mint(msg.sender, _amountToMint);
    }
}