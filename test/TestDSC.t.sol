// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../script/DeployDSC.t.sol";
import {DecentralizedStableCoin} from "../src/DSC.sol";

contract TestDSC is Test {
    DecentralizedStableCoin public dsc;
    address public user = makeAddr("USER");

    function setUp() public {
        DeployDSC deployDSC = new DeployDSC();
        dsc = deployDSC.run();

        uint256 userBalance = 10 ether;
        vm.deal(user, userBalance); // Sets the balance of user to 10 ether
    }

    function testName() public view {
        string memory expectedName = "DecentralizedCoin";
        string memory constructorName = dsc.name();
        assertEq(expectedName, constructorName);
    }

    function testSymbol() public view {
        string memory expectedSymbol = "DSC";
        string memory constructorSymbol = dsc.symbol();
        assertEq(expectedSymbol, constructorSymbol);
    }

    function testRevertIfNotOwnerCallsMintFunction() public {
        vm.prank(user);

        vm.expectRevert();
        dsc.mint(user, 100);
    }

    function testRevertIfNotOwnerCallsBurnFunction() public {
        vm.prank(user);

        vm.expectRevert();
        dsc.burn(100);
    }

    function testRevertIfAmountIsZero() public {
        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        vm.expectRevert(DecentralizedStableCoin.DSC__AmountShouldBeMoreThanZero.selector);
        dsc.mint(user, 0);
    }

    function testRevertIfAddressIsZero() public {
        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        vm.expectRevert(DecentralizedStableCoin.DSC__AccountAddressCannotBeZero.selector);
        dsc.mint(address(0), 10);
    }

    function testBalanceOfUserAfterMint() public {
        vm.deal(msg.sender, 10 ether);

        uint256 balanceBeforeMint = dsc.balanceOf(user);
        uint256 amountToMint = 10;

        vm.prank(msg.sender);
        dsc.mint(user, amountToMint);

        uint256 balanceAfterMint = dsc.balanceOf(user);
        assertEq(balanceAfterMint, balanceBeforeMint + amountToMint);
    }

    function testRevertBurnIfAmountIsZero() public {
        vm.prank(msg.sender);
        vm.deal(msg.sender, 10 ether);
        vm.expectRevert(DecentralizedStableCoin.DSC__AmountShouldBeMoreThanZero.selector);
        dsc.burn(0);
    }

    function testRevertIfBurnAmountExceedsBalance() public {
        vm.deal(msg.sender, 10 ether);

        uint256 amountToMint = 10;
        vm.startPrank(msg.sender);

        dsc.mint(msg.sender, amountToMint);

        uint256 balanceOfSender = dsc.balanceOf(msg.sender);
        
        vm.expectRevert(abi.encodeWithSelector(DecentralizedStableCoin.DSC__BurnAmountCannotExeedBalance.selector, balanceOfSender));
        dsc.burn(100);

        vm.stopPrank();
    }

    function testBurnAmount() public {
        vm.deal(msg.sender, 10 ether);

        uint256 amountToMint = 10;
        vm.startPrank(msg.sender);

        dsc.mint(msg.sender, amountToMint);
        
        uint256 amountToBurn = 10;
        dsc.burn(amountToBurn);

        vm.stopPrank();
    }
}
