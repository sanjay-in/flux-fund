// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {Router} from "../src/Router.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRouter is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() public returns(Router) {
        HelperConfig helperConfig = new HelperConfig();

        (HelperConfig.TokenDetails memory wbtc, HelperConfig.TokenDetails memory weth, HelperConfig.TokenDetails memory link) = helperConfig.networkConfig();

        tokenAddresses = [wbtc.tokenAddress, weth.tokenAddress, link.tokenAddress];
        priceFeedAddresses = [wbtc.priceFeedAddress, weth.priceFeedAddress, link.priceFeedAddress];

        vm.startBroadcast();
        Router router = new Router(tokenAddresses, priceFeedAddresses);
        vm.stopBroadcast();

        return router;
    }
}
