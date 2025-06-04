// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Sanjay S (03 Jun 2025)
 * @notice DSC coin is a stable coin its value is pegged to USD.
 * @notice This contract is owned by the router contract and the router contract can mint and burn them 
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DSC__AccountAddressCannotBeZero();
    error DSC__AmountShouldBeMoreThanZero();
    error DSC__BurnAmountCannotExeedBalance(uint256 _balance);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender) {}

    /**
     * This function calls the ERC20's mint function with custom checks
     * @param _account to who the token should be minted
     * @param _amount of tokens to be minted
     */
    function mint(address _account, uint256 _amount) external onlyOwner {
        if (_amount == 0) {
            revert DSC__AmountShouldBeMoreThanZero();
        }
        if (_account == address(0)) {
            revert DSC__AccountAddressCannotBeZero();
        }
        _mint(_account, _amount);
    }

    /**
     * This function calls the ERC20's burn function with custom checks
     * @param _amount of tokens to burn
     */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount == 0) {
            revert DSC__AmountShouldBeMoreThanZero();
        }
        if (_amount > balance) {
            revert DSC__BurnAmountCannotExeedBalance(balance);
        }
        super.burn(_amount);
    }
}