// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

interface IMinter {
    function mint(address _receiver, uint256 _amount) external;
}