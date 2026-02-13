// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {Script} from "forge-std/Script.sol";
import {AuditorHelper, CodeConstants} from "./AuditorHelper.s.sol";
import {AuditorRegistry} from "../src/auditor/AuditorRegistry.sol";
import {
    VRFCoordinatorV2_5Mock
} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * @notice ***Helper contract that sets up VRF subscription and deploys AuditorRegistry
 *         in a single transaction to avoid blockhash-dependent subscription ID mismatch
 *         between forge script simulation and broadcast.
 */
contract AuditorRegistryDeployer {
    function deploy(
        address vrfCoordinator,
        uint256 fundAmount,
        address priceFeed,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) external returns (AuditorRegistry, uint256) {
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
            subId,
            fundAmount
        );

        AuditorRegistry auditorRegistry = new AuditorRegistry(
            priceFeed,
            vrfCoordinator,
            keyHash,
            subId,
            callbackGasLimit
        );

        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            address(auditorRegistry)
        );

        return (auditorRegistry, subId);
    }
}

contract DeployAuditorRegistry is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 300 ether;

    function run() external returns (AuditorRegistry, AuditorHelper) {
        AuditorHelper helper = new AuditorHelper();
        AuditorHelper.Config memory config = helper.getConfig();

        if (config.subscriptionId == 0 && block.chainid == LOCAL_CHAIN_ID) {
            // Local chain: use deployer helper to bundle all VRF operations
            // into a single transaction, avoiding subscription ID mismatch
            // caused by blockhash changing between simulation and broadcast
            vm.startBroadcast(config.account);
            AuditorRegistryDeployer deployer = new AuditorRegistryDeployer();
            (AuditorRegistry anvilAuditorRegistry, ) = deployer.deploy(
                config.vrfCoordinator,
                FUND_AMOUNT,
                config.priceFeed,
                config.keyHash,
                config.callbackGasLimit
            );
            vm.stopBroadcast();
            return (anvilAuditorRegistry, helper);
        }

        vm.startBroadcast(config.account);
        AuditorRegistry auditorRegistry = new AuditorRegistry(
            config.priceFeed,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (auditorRegistry, helper);
    }
}
