// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {Router} from "../src/Router.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRouter is Script {
    HelperConfig helperConfig;

    ERC20Mock wbtc;
    ERC20Mock weth;
    ERC20Mock link;

    MockV3Aggregator wbtcMockAggregator;
    MockV3Aggregator wethMockAggregator;
    MockV3Aggregator linkMockAggregator;

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() public returns(Router) {
        helperConfig = new HelperConfig();

        (HelperConfig.TokenDetails memory wbtc, HelperConfig.TokenDetails memory weth, HelperConfig.TokenDetails memory link) = helperConfig.networkConfig();

        tokenAddresses = [wbtc.tokenAddress, weth.tokenAddress, link.tokenAddress];
        priceFeedAddresses = [wbtc.priceFeedAddress, weth.priceFeedAddress, link.priceFeedAddress];

        vm.startBroadcast();
        Router router = new Router(tokenAddresses, priceFeedAddresses);
        vm.stopBroadcast();

        return router;
    }

    function getTokenAndPriceFeedAddresses() public returns(address[] memory, address[] memory) {
        return (tokenAddresses, priceFeedAddresses);
    }

    function getERC20Mocks() public returns(ERC20Mock _wbtc, ERC20Mock _weth, ERC20Mock _link) {
        _wbtc = helperConfig.wbtcToken();
        _weth = helperConfig.wethToken();
        _link = helperConfig.linkToken();
    }

    function getMockAggregators() public returns(MockV3Aggregator _wbtc, MockV3Aggregator _weth, MockV3Aggregator _link) {
        _wbtc = helperConfig.wbtcUSDPrice();
        _weth = helperConfig.wethUSDPrice();
        _link = helperConfig.linkUSDPrice();
    }
}
