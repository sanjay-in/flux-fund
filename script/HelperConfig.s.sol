// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";


contract HelperConfig is Script {
    NetworkConfig public networkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant WETH_USD_PRICE = 3000e8;
    int256 public constant WBTC_USD_PRICE = 100000e8;
    int256 public constant AVAX_USD_PRICE = 14e8;
    int256 public constant LINK_USD_PRICE = 13e8;

    struct TokenDetails {
        address tokenAddress;
        address priceFeedAddress;
    }

    struct NetworkConfig {
        TokenDetails wbtc;
        TokenDetails weth;
        TokenDetails link;
        TokenDetails avax;
    }

    constructor() {
        if (block.chainid == 11155111) {
            networkConfig = null;
        } else {
            networkConfig = foundryConfig();
        }
    }

    function foundryConfig() public returns(NetworkConfig memory foundryConfigDetails) {
        vm.startBroadcast();

        MockV3Aggregator wethUSDPrice = new MockV3Aggregator(DECIMALS, WETH_USD_PRICE);
        MockV3Aggregator wbtcUSDPrice = new MockV3Aggregator(DECIMALS, WBTC_USD_PRICE);
        MockV3Aggregator linkUSDPrice = new MockV3Aggregator(DECIMALS, LINK_USD_PRICE);
        MockV3Aggregator avaxUSDPrice = new MockV3Aggregator(DECIMALS, AVAX_USD_PRICE);

        ERC20Mock wethToken = new ERC20Mock();
        ERC20Mock wbtcToken = new ERC20Mock();
        ERC20Mock linkToken = new ERC20Mock();
        ERC20Mock avaxToken = new ERC20Mock();

        vm.stopBroadcast();

        foundryConfigDetails = NetworkConfig({
            wbtc: {
                tokenAddress: address(wbtcToken),
                priceFeedAddress: address(wbtcUSDPrice),
            },
             weth: {
                tokenAddress: address(wethToken),
                priceFeedAddress: address(wethUSDPrice),
            },
            link: {
                tokenAddress: address(linkToken),
                priceFeedAddress: address(linkUSDPrice),
            },
            wbtc: {
                tokenAddress: address(avaxToken),
                priceFeedAddress: address(avaxUSDPrice),
            },
        })
    }
}