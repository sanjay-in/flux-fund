// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {Router} from "../src/Router.sol";
import {Deposit} from "../src/Deposit.sol";
import {Minter} from "../src/Minter.sol";
import {DecentralizedStableCoin} from "../src/DSC.sol";
import {DeployRouter} from "../script/DeployRouter.s.sol";

contract TestDeposit is Test {
    Router public router;
    Deposit public deposit;
    Minter public minter;
    DecentralizedStableCoin public dsc;
    ERC20Mock public token1;
    ERC20Mock public token2;
    ERC20Mock public token3;
    MockV3Aggregator public token1MockAggregator;
    
    error OwnableUnauthorizedAccount(address account);
    error Deposit__TokenNotAllowed(address _tokenAddress);

    address public USER = makeAddr("USER");
    uint256 public constant AMOUNT_FOR_USER = 10 ether;
    uint256 public constant AMOUNT_TO_MINT = 1000e18;
    uint8 public constant MOCK_AGGREGATOR_DECIMALS = 8;
    int256 public constant MOCK_AGGREGATOR_TOKEN1_INITIAL_VALUE = 100e8;

    address allowedToken1;
    address allowedToken2;
    address allowedToken3;

    function setUp() public {
        DeployRouter deployRouter = new DeployRouter();
        (router) = deployRouter.run();

        deposit = new Deposit(address(router));
        minter = new Minter(address(router));
        dsc = minter.getDecentralizedStableCoin();

        token1 = new ERC20Mock();
        token2 = new ERC20Mock();
        token3 = new ERC20Mock();

        allowedToken1 = address(token1);
        allowedToken2 = address(token2);
        allowedToken3 = address(token3);
        
        deposit.setAllowedTokens(allowedToken1, true);
        deposit.setAllowedTokens(allowedToken2, true);
        deposit.setAllowedTokens(allowedToken3, true);

        token1MockAggregator = new MockV3Aggregator(MOCK_AGGREGATOR_DECIMALS, MOCK_AGGREGATOR_TOKEN1_INITIAL_VALUE);
        vm.prank(msg.sender);
        router.addTokens(allowedToken1, address(token1MockAggregator));

        vm.deal(USER, AMOUNT_FOR_USER);
        token1.mint(USER, AMOUNT_TO_MINT);
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
        allowedToken1 = address(0);
        
        vm.expectRevert(Deposit.Deposit__ZeroAddress.selector);
        deposit.setAllowedTokens(allowedToken1, true);
    }

    function testSetAllowedTokens() public {
        bool token2Status = deposit.getIsAllowedTokens(allowedToken2);
        assertEq(token2Status, true);

        deposit.setAllowedTokens(allowedToken2, false);
        token2Status = deposit.getIsAllowedTokens(allowedToken2);
        assertEq(token2Status, false);
    }

    // Functions test

    function testRevertOnDeposit() public {
        address zeroAddress = address(0);
        address tokenAddress = makeAddr("token4");
        uint256 amount = 100;
        uint256 userFee = 0.5 ether;
        address user = makeAddr("user");

        vm.deal(user, 10);

        vm.startPrank(user);
        vm.expectRevert(Deposit.Deposit__ZeroAddress.selector);
        deposit.deposit(zeroAddress, amount);

        vm.expectRevert(Deposit.Deposit__ZeroAmount.selector);
        deposit.deposit(allowedToken1, 0);

        bool token2Status = deposit.getIsAllowedTokens(tokenAddress);
        // vm.expectRevert(Deposit.Deposit__TokenNotAllowed.selector, address(tokenAddress));
        vm.expectRevert(abi.encodeWithSelector(Deposit__TokenNotAllowed.selector, tokenAddress));
        deposit.deposit(tokenAddress, amount);
        vm.stopPrank();
    }

    function testDepositCollateral() public {
        uint256 amountToDeposit = 100e18;
        uint256 userFeeToSpend = 0.5 ether;

        vm.startPrank(USER);
        token1.approve(address(deposit), amountToDeposit);

        deposit.deposit{value: userFeeToSpend}(allowedToken1, amountToDeposit);

        uint256 amountDeposited = deposit.getUserTokenAmount(allowedToken1);
        assertEq(amountDeposited, amountToDeposit);

        uint256 userFeeDeposited = deposit.getUserFeeValue();
        assertEq(userFeeDeposited, userFeeToSpend);
        vm.stopPrank();
    }


    function testRedeemCollateral() public {
        uint256 amountToDeposit = 100e18;
        uint256 userFeeToSpend = 0.5 ether;
        uint256 amountToRedeem = 50e18;

        vm.startPrank(USER);
        token1.approve(address(deposit), amountToDeposit);

        deposit.deposit{value: userFeeToSpend}(allowedToken1, amountToDeposit);
        uint256 balanceAfterDeposit = token1.balanceOf(USER);

        deposit.redeem(USER, USER, allowedToken1, amountToRedeem);

        uint256 amountAfterRedeem = deposit.getUserTokenAmount(allowedToken1);
        assertEq(amountAfterRedeem, amountToDeposit - amountToRedeem);  

        uint256 balanceAfterRedeem = token1.balanceOf(USER);
        assertEq(balanceAfterRedeem, balanceAfterDeposit + amountToRedeem);      
        vm.stopPrank();
    }

    function testRevertInDepositAndMint() public {
        address tokenAddress = makeAddr("token4");

        vm.expectRevert(abi.encodeWithSelector(Deposit__TokenNotAllowed.selector, tokenAddress));
        deposit.depositAndMint(tokenAddress, 100, address(minter), USER, 100e18);
    }

    function testDepositAndMint() public {
        uint256 amountToDeposit = 100e18;
        uint256 userFeeToSpend = 0.5 ether;
        uint256 amountToMint = 8000e18;

        vm.startPrank(USER);
        token1.approve(address(deposit), amountToDeposit);

        deposit.depositAndMint{value: userFeeToSpend}(allowedToken1, amountToDeposit, address(minter), USER, amountToMint);

        uint256 dscUserBalance = dsc.balanceOf(USER);
        assertEq(dscUserBalance, amountToMint);

        uint256 token1UserBalance = deposit.getUserTokenAmount(allowedToken1);
        assertEq(token1UserBalance, amountToDeposit);
        vm.stopPrank();
    }

    function testReceiveFunction() public {
        address unknownUser = makeAddr("unknownUser");
        uint256 userFeeToSpend = 0.5 ether;

        vm.deal(unknownUser, 1 ether);

        vm.startPrank(unknownUser);
        payable(address(deposit)).call{value: userFeeToSpend}("");

        uint256 amountUnknownUserSent = deposit.getFeeValue(unknownUser);
        assertEq(amountUnknownUserSent, userFeeToSpend);
    }
}