// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

interface IRouter {
    function liquidate(address _userToLiquidate, address _receiver, address _token, uint256 _amount, address _sender) external;

    function depositCollateral(address _depositor, address _tokenAddress, uint256 _amount) external;
    
    function depositAndMintTokens(address _tokenAddress, uint256 _amountToDeposit, address _receiver, address _depositor, uint256 _amountToMint) external;
}