// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {AuditorHelper, CodeConstants} from "./AuditorHelper.s.sol";
import {AuditorRegistryDeployer} from "./DeployAuditorRegistry.s.sol";
import {ProcessTracking} from "../src/process-tracking/ProcessTracking.sol";
import {TrustComputation} from "../src/trustworthiness/TrustComputation.sol";
import {MetricSelection} from "../src/trustworthiness/MetricSelection.sol";
import {AuditorRegistry} from "../src/auditor/AuditorRegistry.sol";
import {LogDefaultPackage} from "../src/trustworthiness/packages/LogDefaultPackage.sol";
import {LogAuditorPackage} from "../src/trustworthiness/packages/LogAuditorPackage.sol";

contract Interaction is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 300 ether;

    function run() external {
        AuditorHelper helper = new AuditorHelper();
        AuditorHelper.Config memory config = helper.getConfig();

        vm.startBroadcast(config.account);

        // Deploy core contracts
        ProcessTracking processTracking = new ProcessTracking();
        console.log("ProcessTracking deployed at:", address(processTracking));

        MetricSelection metricSelection = new MetricSelection();
        TrustComputation trustComputation = new TrustComputation(address(metricSelection));
        console.log("TrustComputation deployed at:", address(trustComputation));

        // Deploy AuditorRegistry
        AuditorRegistry auditorRegistry;
        if (config.subscriptionId == 0 && block.chainid == LOCAL_CHAIN_ID) {
            AuditorRegistryDeployer deployer = new AuditorRegistryDeployer();
            (auditorRegistry,) = deployer.deploy(
                config.vrfCoordinator, FUND_AMOUNT, config.priceFeed, config.keyHash, config.callbackGasLimit
            );
        } else {
            auditorRegistry = new AuditorRegistry(
                config.priceFeed, config.vrfCoordinator, config.keyHash, config.subscriptionId, config.callbackGasLimit
            );
        }
        console.log("AuditorRegistry deployed at:", address(auditorRegistry));

        // Deploy trust packages
        LogDefaultPackage logDefaultPackage = new LogDefaultPackage();
        console.log("LogDefaultPackage deployed at:", address(logDefaultPackage));

        LogAuditorPackage logAuditorPackage = new LogAuditorPackage(address(auditorRegistry));
        console.log("LogAuditorPackage deployed at:", address(logAuditorPackage));

        metricSelection.registerTrustPackage("log", "default", address(logDefaultPackage));
        metricSelection.registerTrustPackage("log", "auditor", address(logAuditorPackage));

        vm.stopBroadcast();
    }
}
