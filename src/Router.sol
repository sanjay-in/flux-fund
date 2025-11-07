// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface, OracleLib} from "./library/OracleLib.sol";
import {IMinter} from "./interface/IMinter.sol";

contract Router is Ownable {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    error Router__TokenNotSupported();
    error Router__AmountShouldBeMoreThanZero();
    error Router__TokenAlreadyExist();

    address[] public s_allowedTokenAddresses;

    mapping (address user => mapping (address tokenAdress => uint256 amount)) public s_userDepositAmount;
    mapping (address user => uint256 amount) public s_userMintedStableCoin;

    mapping (address tokenAddress => bool active) public s_isTokenAllowed;
    mapping (address collateralToken => address priceFeed) public s_priceFeeds;

    uint256 private constant LIQUIDATION_THRESHOLD = 80e18; // 80%
    uint256 private constant LIQUIDATION_PRECISION = 1e20; // 100 => LIQUIDATION_THRESHOLD/LIQUIDATION_PRECISION (80/100)
    uint256 private constant MINIMUM_HEALTH_FACTOR = 1e18;
    uint256 private constant ADDITIONAL_FEE_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    event CollateralDeposited(address indexed user, address indexed tokenAddress, uint256 amount);
    event MintedStableCoin(address indexed user, uint256 _amount);

    modifier onlyAllowedTokens(address _token) {
        if (!s_isTokenAllowed[_token]) {
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

    constructor(address[] memory _tokenAddresses) Ownable(msg.sender) {
        s_allowedTokenAddresses = _tokenAddresses;
    }

    /**
     * @notice This is an exernal function that deposits collateral and mints stable coin in one transaction
     * @param _tokenAddress address of the collateral
     * @param _amountToDeposit amount of collateral the user wants to deposit
     * @param _amountToMint amount of stablecoin user wishes to mint
     */
    function depositAndMintTokens(address _tokenAddress, uint256 _amountToDeposit, address _receiver, address _depositor, uint256 _amountToMint) external {
        depositCollateral(_tokenAddress, _amountToDeposit);
        _mint(_receiver, _depositor, _amountToMint);
    }

    /**
     * @notice Deposits collateral into the protocol
     * Checks if the collateral is supported
     * Checks if the collateral value is more than zero
     * @param _tokenAddress address of the collateral
     * @param _amount amount of collateral the user wants to deposit
     */
    function depositCollateral(address _tokenAddress, uint256 _amount) public moreThanZero(_amount) {
        s_userDepositAmount[msg.sender][_tokenAddress] += _amount;
        emit CollateralDeposited(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @notice This function mints stablecoins if you have enough health factor
     * @param _amountToMint amount of stablecoin user wish wishes to mint
     */
    function mintTokens(address _receiver, uint256 _amountToMint) public moreThanZero(_amountToMint) {
       _mint(_receiver, msg.sender, _amountToMint);
    }

    function addTokens(address _tokenAddress, address _priceFeedAddress) external onlyOwner {
        if (s_isTokenAllowed[_tokenAddress]) {
            revert Router__TokenAlreadyExist();
        }
        s_isTokenAllowed[_tokenAddress] = true;
        s_priceFeeds[_tokenAddress] = _priceFeedAddress;
        s_allowedTokenAddresses.push(_tokenAddress);
    }

    function removeAllowedToken(address _tokenAddress) external onlyAllowedTokens(_tokenAddress) onlyOwner {
        s_isTokenAllowed[_tokenAddress] = false;
        s_priceFeeds[_tokenAddress] = address(0);
    }

    function changePriceFeed(address _tokenAddress, address _priceFeed) external onlyAllowedTokens(_tokenAddress) onlyOwner {
        s_priceFeeds[_tokenAddress] = _priceFeed;
    }

    function getUserDepositedAndMintedTokens(address _user) public view returns(uint256 _deposited, uint256 _minted) {
        _deposited = getUserOverallCollateralValue(_user);
        _minted = getUserOverallMinted(_user);
    }

    function getUserOverallCollateralValue(address _user) public view returns(uint256 totalAmount) {
        uint256 _tokenLength = s_allowedTokenAddresses.length;
        for (uint256 i = 0; i < _tokenLength; i++) {
            uint256 _tokenAddress = s_allowedTokenAddresses[i];
            uint256 _userAmount = s_userDepositAmount[_user][_tokenAddress];
            if (_userAmount) {
                totalAmount += _getUSDValue(_tokenAddress, _userAmount);
            }
        }
    }

    function getUserOverallMinted(address _user) public view returns(uint256) {
        return s_userMintedStableCoin[_user];
    }

    function _mint(address _receiver, address _sender, uint256 _amount) internal {
        s_userMintedStableCoin[_sender] += _amount;
        IMinter(_receiver).mint(_sender, _amount);
    }

    /**
     * @notice Calculates the health factor of the user
     * @param _user address to check health factor
     * @return healthFactor with precision
     */
    function _getHealthFactor(address _user) internal view returns(uint256 healthFactor) {
        uint256 _userCollateral = getUserOverallCollateralValue(_user);
        uint256 _userMinted = getUserOverallMinted(_user);
        healthFactor = (_userCollateral * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        healthFactor = (healthFactor * PRECISION) / _userMinted;
    }

    function _getUSDValue(address _token, uint256 _amount) internal view returns(uint256) {
        AggregatorV3Interface chainlinkFeed = AggregatorV3Interface(s_priceFeeds[_token]);
        (,int256 price,,,) = chainlinkFeed.getLatestRoundData();
        return ((uint256(price) * ADDITIONAL_FEE_PRECISION) * _amount) / PRECISION;
    }

    function _calculateHealthFactor(uint256 _totalValueDeposited, uint256 _totalValueMinted) internal pure returns (uint256) {
        uint256 _amount =  (_totalValueDeposited * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return ( _amount * PRECISION ) / _totalValueMinted;
    }
}