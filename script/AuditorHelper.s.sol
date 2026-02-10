// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract AuditorHelper is Script {
    error AuditorHelper__InvalidConfig();

    struct Config {
        address priceFeed;
    }

    uint8 private constant DECIMALS = 8;
    int256 private constant INITIAL_PRICE = 2000e8;

    uint256 public constant ANVIL_CHAIN_ID = 31337;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;

    mapping(uint256 chainId => Config config) chainIdToConfig;

    constructor() {
        chainIdToConfig[SEPOLIA_CHAIN_ID] = getEthUsdSepoliaConfig();
        chainIdToConfig[ZKSYNC_SEPOLIA_CHAIN_ID] = getEthUsdZksyncSepoliaConfig();
    }

    function getConfig() public returns (Config memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (Config memory) {
        if (chainIdToConfig[chainId].priceFeed != address(0)) {
            return chainIdToConfig[chainId];
        } else if (block.chainid == ANVIL_CHAIN_ID) {
            return getEthUsdAnvilConfig();
        }
        revert AuditorHelper__InvalidConfig();
    }

    function getEthUsdSepoliaConfig() internal pure returns (Config memory) {
        return Config({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
    }

    function getEthUsdZksyncSepoliaConfig() internal pure returns (Config memory) {
        return Config({priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF});
    }

    function getEthUsdAnvilConfig() internal returns (Config memory) {
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        return Config({priceFeed: address(mock)});
    }
}
