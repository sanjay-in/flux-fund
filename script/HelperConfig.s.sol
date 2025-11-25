// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Parameter} from "./Parameter.sol";


contract HelperConfig is Script, Parameter {
    struct TokenDetails {
        address tokenAddress;
        address priceFeedAddress;
    }

    struct NetworkConfig {
        TokenDetails wbtc;
        TokenDetails weth;
        TokenDetails link;
    }

    NetworkConfig public networkConfig;

    ERC20Mock public wethToken;
    ERC20Mock public wbtcToken;
    ERC20Mock public linkToken;

    MockV3Aggregator public wethUSDPrice;
    MockV3Aggregator public wbtcUSDPrice;
    MockV3Aggregator public linkUSDPrice;

    uint8 public constant DECIMALS = 8;
    int256 public constant WETH_USD_PRICE = 3000e8;
    int256 public constant WBTC_USD_PRICE = 100000e8;
    int256 public constant LINK_USD_PRICE = 13e8;

    constructor() {
        if (block.chainid == 421614) {
            networkConfig = arbitrumSepoliaConfig();
        } if (block.chainid == 43113) {
            networkConfig = avalancheFujiConfig();
        } if (block.chainid == 84532) {
            networkConfig = baseSepoliaConfig();
        } if (block.chainid == 11155111) {
            networkConfig = ethSepoliaConfig();
        } if (block.chainid == 80002) {
            networkConfig = polygonAmoyConfig();
        } if (block.chainid == 300) {
            networkConfig = zkSyncSepoliaConfig();
        } else {
            networkConfig = foundryConfig();
        }
    }

    function foundryConfig() public returns(NetworkConfig memory foundryConfigDetails) {
        vm.startBroadcast();

        wethUSDPrice = new MockV3Aggregator(DECIMALS, WETH_USD_PRICE);
        wbtcUSDPrice = new MockV3Aggregator(DECIMALS, WBTC_USD_PRICE);
        linkUSDPrice = new MockV3Aggregator(DECIMALS, LINK_USD_PRICE);

        wethToken = new ERC20Mock();
        wbtcToken = new ERC20Mock();
        linkToken = new ERC20Mock();

        vm.stopBroadcast();

        foundryConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: address(wbtcToken),
                priceFeedAddress: address(wbtcUSDPrice)
            }),
            weth: TokenDetails({
                tokenAddress: address(wethToken),
                priceFeedAddress: address(wethUSDPrice)
            }),
            link: TokenDetails({
                tokenAddress: address(linkToken),
                priceFeedAddress: address(linkUSDPrice)
            })
        });
    }

    function arbitrumSepoliaConfig() public returns(NetworkConfig memory arbitrumSepoliaConfigDetails) {
        arbitrumSepoliaConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: ARBITRUM_SEPOLIA_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: ARBITRUM_SEPOLIA_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: ARBITRUM_SEPOLIA_WETH_TOKEN_ADDRESS,
                priceFeedAddress: ARBITRUM_SEPOLIA_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: ARBITRUM_SEPOLIA_LINK_TOKEN_ADDRESS,
                priceFeedAddress: ARBITRUM_SEPOLIA_LINK_PRICEFEED_ADDRESS
            })
        });
    }

    function avalancheFujiConfig() public returns(NetworkConfig memory avalancheFujiConfigDetails) {
        avalancheFujiConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: AVALANCHE_FUJI_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: AVALANCHE_FUJI_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: AVALANCHE_FUJI_WETH_TOKEN_ADDRESS,
                priceFeedAddress: AVALANCHE_FUJI_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: AVALANCHE_FUJI_LINK_TOKEN_ADDRESS,
                priceFeedAddress: AVALANCHE_FUJI_LINK_PRICEFEED_ADDRESS
            })
        });
    }

    function baseSepoliaConfig() public returns(NetworkConfig memory baseSepoliaConfigDetails) {
        baseSepoliaConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: BASE_SEPOLIA_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: BASE_SEPOLIA_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: BASE_SEPOLIA_WETH_TOKEN_ADDRESS,
                priceFeedAddress: BASE_SEPOLIA_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: BASE_SEPOLIA_LINK_TOKEN_ADDRESS,
                priceFeedAddress: BASE_SEPOLIA_LINK_TOKEN_ADDRESS
            })
        });
    }

    function ethSepoliaConfig() public returns(NetworkConfig memory ethSepoliaConfigDetails) {
        ethSepoliaConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: ETH_SEPOLIA_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: ETH_SEPOLIA_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: ETH_SEPOLIA_WETH_TOKEN_ADDRESS,
                priceFeedAddress: ETH_SEPOLIA_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: ETH_SEPOLIA_LINK_TOKEN_ADDRESS,
                priceFeedAddress: ETH_SEPOLIA_LINK_PRICEFEED_ADDRESS
            })
        });
    }

    function polygonAmoyConfig() public returns(NetworkConfig memory polygonAmoyConfigDetails) {
        polygonAmoyConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: POLYGON_AMOY_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: POLYGON_AMOY_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: POLYGON_AMOY_WETH_TOKEN_ADDRESS,
                priceFeedAddress: POLYGON_AMOY_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: POLYGON_AMOY_LINK_TOKEN_ADDRESS,
                priceFeedAddress: POLYGON_AMOY_LINK_PRICEFEED_ADDRESS
            })
        });
    }

    function zkSyncSepoliaConfig() public returns(NetworkConfig memory zkSyncSepoliaConfigDetails) {
        zkSyncSepoliaConfigDetails = NetworkConfig({
            wbtc: TokenDetails({
                tokenAddress: ZKSYNC_SEPOLIA_WBTC_TOKEN_ADDRESS,
                priceFeedAddress: ZKSYNC_SEPOLIA_WBTC_PRICEFEED_ADDRESS
            }),
            weth: TokenDetails({
                tokenAddress: ZKSYNC_SEPOLIA_WETH_TOKEN_ADDRESS,
                priceFeedAddress: ZKSYNC_SEPOLIA_WETH_PRICEFEED_ADDRESS
            }),
            link: TokenDetails({
                tokenAddress: ZKSYNC_SEPOLIA_LINK_TOKEN_ADDRESS,
                priceFeedAddress: ZKSYNC_SEPOLIA_LINK_PRICEFEED_ADDRESS
            })
        });
    }
}