// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

interface IDepositor {
    function redeem(address _from, address _to, address _token, uint256 _amount) external;
}