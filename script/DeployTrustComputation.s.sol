// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TrustComputation} from "../src/trustworthiness/TrustComputation.sol";
import {MetricSelection} from "../src/trustworthiness/MetricSelection.sol";
import {
    LogDefaultPackage
} from "../src/trustworthiness/packages/LogDefaultPackage.sol";
import {
    LogAuditorPackage
} from "../src/trustworthiness/packages/LogAuditorPackage.sol";
import {DeployAuditorRegistry} from "./DeployAuditorRegistry.s.sol";

contract DeployTrustComputation is Script {
    function run() external returns (TrustComputation) {
        vm.startBroadcast();

        MetricSelection metricSelection = new MetricSelection();

        TrustComputation trustComputation = new TrustComputation(
            address(metricSelection)
        );

        vm.stopBroadcast();
        return trustComputation;
    }
}
