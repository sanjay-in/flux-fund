// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {DeployRouter} from "../../script/DeployRouter.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Router} from "../../src/Router.sol";
import {Deposit} from "../../src/Deposit.sol";
import {Minter} from "../../src/Minter.sol";
import {DecentralizedStableCoin} from "../../src/DSC.sol";

contract TestMinter is Test {
    Router public router;
    Deposit public deposit;
    Minter public minter;
    DecentralizedStableCoin public dsc;
    ERC20Mock wethToken;
    MockV3Aggregator wethAggregator;

    address public USER = makeAddr("USER");
    uint256 public constant AMOUNT_TO_DEPOSIT = 2400e18;
    uint256 public constant AMOUNT_FOR_USER = 10 ether;
    uint256 public constant USER_FEE = 0.5 ether;
    
    address wethTokenAddress;
    address wethPriceFeedAddress;

    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        DeployRouter deployRouter = new DeployRouter();
        (router) = deployRouter.run();

        deposit = new Deposit(address(router));
        minter = new Minter(address(router));
        HelperConfig helperConfig = new HelperConfig();
        dsc = minter.getDecentralizedStableCoin();

        (address[] memory tokenAddresses, address[] memory pricFeedAddresses) = deployRouter.getTokenAndPriceFeedAddresses();
        wethTokenAddress = tokenAddresses[1];
        wethPriceFeedAddress = pricFeedAddresses[1];

        (,wethToken,) = deployRouter.getERC20Mocks();

        (,wethAggregator,) = deployRouter.getMockAggregators();

        vm.deal(USER, AMOUNT_FOR_USER);
        deposit.setAllowedTokens(wethTokenAddress, true);

        vm.startPrank(USER);
        wethToken.mint(USER, AMOUNT_TO_DEPOSIT);
        wethToken.approve(address(deposit), AMOUNT_TO_DEPOSIT);
        deposit.deposit{value: USER_FEE}(wethTokenAddress, AMOUNT_TO_DEPOSIT);
        vm.stopPrank();
    }

    // Constructor test
    function testConstructor() public {
        address fetchedMainRouterAddress = minter.getMainRouterAddress();
        assertEq(fetchedMainRouterAddress, address(router));
    }

    // Receive function test
    function testMinterReceiveFunction() public {
        address unknownUser = makeAddr("unknownUser");
        uint256 userFeeToSpend = 0.5 ether;

        vm.deal(unknownUser, 1 ether);

        vm.startPrank(unknownUser);
        payable(address(minter)).call{value: userFeeToSpend}("");

        uint256 amountUnknownUserSent = minter.getUserFee(unknownUser);
        assertEq(amountUnknownUserSent, userFeeToSpend);
    }

    // Setter function test
     function testRevertOnSetMainRouter() public {
        address newAddress = address(1);
        address newOwner = makeAddr("newOwner");

        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, newOwner));
        vm.prank(newOwner);
        minter.setMainRouter(newAddress);
    }
    
    function testSetMainRouter() public {
        address newAddress = address(1);

        minter.setMainRouter(newAddress);
        address newSetAddress = minter.getMainRouterAddress();
        assertEq(newSetAddress, newAddress);
    }

    // Main function test
    function testRevertOnMint() public {
        vm.expectRevert(Minter.Minter__ZeroAddress.selector);
        minter.mint(address(0), 100e18);
        
        vm.expectRevert(Minter.Minter__ZeroAmount.selector);
        minter.mint(USER, 0);

        vm.expectRevert(Minter.Minter__CallerIsNotRouterContract.selector);
        minter.mint(USER, 100e18);
    }

    function testMinterMint() public {
        uint256 dscToMint = 100e18;
        uint256 userBalanceBeforeMinted = minter.getMintedAmountForUser(USER);
        assertEq(0, userBalanceBeforeMinted);

        vm.prank(address(router));
        minter.mint(USER, dscToMint);

        uint256 userBalanceAfterMinted = minter.getMintedAmountForUser(USER);
        assertEq(dscToMint, userBalanceAfterMinted);
    }

    function testMinterRevertOnBurn() public {
        vm.expectRevert(Minter.Minter__ZeroAddress.selector);
        minter.burn(address(0), 100e18);
        
        vm.expectRevert(Minter.Minter__ZeroAmount.selector);
        minter.burn(USER, 0);
    }

    function testMinterBurnFunction() public {
        uint256 dscToMint = 100e18;
        uint256 dscToBurn = 50e18;

        vm.prank(address(router));
        minter.mint(USER, dscToMint);

        vm.prank(USER);
        dsc.approve(address(minter), dscToBurn);
        
        minter.burn{value: USER_FEE}(USER, dscToBurn);

        uint256 userBalanceAfterBurned = minter.getMintedAmountForUser(USER);
        assertEq(userBalanceAfterBurned, dscToMint = dscToBurn);
    }

    function testMinterRevertOnLiquidate() public {
        uint256 amountToLiquidate = 800e18;

        vm.expectRevert(Minter.Minter__ZeroAmount.selector);
        minter.liquidate(USER, address(router), wethTokenAddress, 0);

        vm.expectRevert(Minter.Minter__ZeroAddress.selector);
        minter.liquidate(USER, address(router), address(0), amountToLiquidate);

        vm.expectRevert(Minter.Minter__ZeroAddress.selector);
        minter.liquidate(address(0), address(router), wethTokenAddress, amountToLiquidate);
    }

    function testMinterLiquidate() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        uint256 amountToMint = 2400e18;
        uint256 amountToMintForUser2 = 4800e18;
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.startPrank(user1);
        wethToken.mint(user1, 1e18);
        wethToken.approve(address(deposit), 1e18);
        deposit.depositAndMint{value: USER_FEE}(wethTokenAddress, 1e18, address(minter), user1, amountToMint);

        vm.stopPrank();

        vm.startPrank(user2);
        wethToken.mint(user2, 3e18);
        wethToken.approve(address(deposit), 3e18);
        deposit.depositAndMint{value: USER_FEE}(wethTokenAddress, 3e18, address(minter), user2, amountToMintForUser2);

        wethAggregator.updateAnswer(2900e8);
        dsc.approve(address(minter), amountToMintForUser2);
        minter.liquidate(user1, address(deposit), wethTokenAddress, amountToMint);
        vm.stopPrank();

        uint256 dscBalanceForUser2InMinter = minter.getMintedAmountForUser(user2);
        assertEq(dscBalanceForUser2InMinter, amountToMintForUser2 - amountToMint);

        uint256 dscBalanceForUser2InRouter = router.getUserOverallMinted(user2);
        assertEq(dscBalanceForUser2InRouter, amountToMintForUser2 - amountToMint);
    }
}