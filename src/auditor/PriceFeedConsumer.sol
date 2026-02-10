// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceFeedConsumer {
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function convert(uint256 amount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint8 decimals = priceFeed.decimals();
        return (getLatestPrice(priceFeed) * (10 ** (18 - decimals)) * amount) / 1e18;
    }
}
