// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library OracleLib {
    error OracleLib__DataStale();

    uint256 private constant TIMEOUT = 3 hours;

    function getLatestRoundData(AggregatorV3Interface chainlinkFeed) external view returns(uint80, int256, uint256, uint256, uint80) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = chainlinkFeed.latestRoundData();

        // Checks if last updated is 0 || last round answer less than roundId || last updated is more than 3 hours
        if (updatedAt == 0 || answeredInRound < roundId || (block.timestamp - updatedAt) > TIMEOUT) {
            revert OracleLib__DataStale();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function getTimeout() external pure returns (uint256) {
        return TIMEOUT;
    }
}