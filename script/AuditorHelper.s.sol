// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    uint96 public constant BASE_FEE = 0.25 ether;
    uint96 public constant GAS_PRICE = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
}

contract AuditorHelper is Script, CodeConstants {
    error AuditorHelper__InvalidConfig();

    struct Config {
        address priceFeed;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    mapping(uint256 chainId => Config config) chainIdToConfig;

    Config public localNetWorkConfig;

    constructor() {
        chainIdToConfig[SEPOLIA_CHAIN_ID] = getEthUsdSepoliaConfig();
    }

    function getConfig() public returns (Config memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (Config memory) {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return getEthUsdAnvilConfig();
        } else if (
            chainIdToConfig[chainId].priceFeed != address(0) && chainIdToConfig[chainId].vrfCoordinator != address(0)
        ) {
            return chainIdToConfig[chainId];
        }
        revert AuditorHelper__InvalidConfig();
    }

    function getEthUsdSepoliaConfig() internal pure returns (Config memory) {
        return Config({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 48173827586891756093595132381979588514464786466822827527327829072365290294277,
            callbackGasLimit: 100000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x7036A25578d030f719c0503a4Ccab1609E425B34
        });
    }

    function getEthUsdAnvilConfig() public returns (Config memory) {
        if (localNetWorkConfig.vrfCoordinator != address(0)) {
            return localNetWorkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        // setup config
        localNetWorkConfig = Config({
            priceFeed: address(mockV3Aggregator),
            vrfCoordinator: address(vrfCoordinatorV2_5Mock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(linkToken),
            account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // anvil default account // 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // forge-std base sender
        });

        return localNetWorkConfig;
    }
}
