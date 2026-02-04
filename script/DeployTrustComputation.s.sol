// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TrustComputation} from "../src/TrustComputation.sol";
import {MetricSelection} from "../src/MetricSelection.sol";
import {
    LogDefaultTrustPackage
} from "../src/packages/LogDefaultTrustPackage.sol";

contract DeployTrustComputation is Script {
    function run() external returns (TrustComputation) {
        vm.startBroadcast();

        MetricSelection metricSelection = new MetricSelection();
        LogDefaultTrustPackage logDefaultTP = new LogDefaultTrustPackage();
        metricSelection.registerTrustPackage(
            "log",
            "default",
            address(logDefaultTP)
        );
        TrustComputation trustComputation = new TrustComputation(
            address(metricSelection)
        );

        vm.stopBroadcast();
        return trustComputation;
    }
}
