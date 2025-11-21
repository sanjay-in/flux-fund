// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {Deposit} from "../src/Deposit.sol";
import {DeployRouter} from "../script/DeployRouter.s.sol";

contract TestDeposit is Test {
    Router public router;
    Deposit public deposit;
    
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        DeployRouter deployRouter = new DeployRouter();
        (router) = deployRouter.run();

        deposit = new Deposit(address(router));
    }

    // Constructor test

    function testMainRouterAddress() public {
        address fetchedMainRouterAddress = deposit.getMainRouterAddress();
        assertEq(fetchedMainRouterAddress, address(router));
    }

    // Setter functions tests

    function testRevertOnSetMainRouter() public {
        address newAddress = address(1);
        address newOwner = makeAddr("newOwner");

        vm.startPrank(newOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, newOwner));
        deposit.setMainRouterAddress(newAddress);
        vm.stopPrank();
    }

    function testSetMainRouter() public {
        address newAddress = address(1);
        deposit.setMainRouterAddress(newAddress);
        address fetchedMainRouterAddress = deposit.getMainRouterAddress();

        assertEq(fetchedMainRouterAddress, newAddress);
    }

    function testRevertSetAllowedTokenZeroAddress() public {
        address allowedToken1 = address(0);
        
        vm.expectRevert(Deposit.Deposit__ZeroAddress.selector);
        deposit.setAllowedTokens(allowedToken1, true);
    }

    function testSetAllowedTokens() public {
        address allowedToken1 = makeAddr("Token1");
        address allowedToken2 = makeAddr("Token2");
        address allowedToken3 = makeAddr("Token3");
        
        deposit.setAllowedTokens(allowedToken1, true);
        deposit.setAllowedTokens(allowedToken2, true);
        deposit.setAllowedTokens(allowedToken3, true);
        
        bool token2Status = deposit.getIsAllowedTokens(allowedToken2);
        assertEq(token2Status, true);

        deposit.setAllowedTokens(allowedToken2, false);
        token2Status = deposit.getIsAllowedTokens(allowedToken2);
        assertEq(token2Status, false);
    }
}