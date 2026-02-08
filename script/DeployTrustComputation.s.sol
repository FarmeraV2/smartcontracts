// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {TrustComputation} from "../src/TrustComputation.sol";
import {MetricSelection} from "../src/MetricSelection.sol";
import {LogDefaultTrustPackage} from "../src/packages/LogDefaultTrustPackage.sol";
import {StepTransparencyPackage} from "../src/packages/StepTransparencyPackage.sol";

contract DeployTrustComputation is Script {
    function run() external returns (TrustComputation) {
        vm.startBroadcast();

        MetricSelection metricSelection = new MetricSelection();

        LogDefaultTrustPackage logDefaultTP = new LogDefaultTrustPackage();
        metricSelection.registerTrustPackage("log", "default", address(logDefaultTP));

        StepTransparencyPackage stepTP = new StepTransparencyPackage();
        metricSelection.registerTrustPackage("step", "default", address(stepTP));

        TrustComputation trustComputation = new TrustComputation(address(metricSelection));

        console.log("TrustComputation deployed at:", address(trustComputation));

        vm.stopBroadcast();
        return trustComputation;
    }
}
