// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {ProcessTracking} from "../src/process-tracking/ProcessTracking.sol";

contract DeployProcessTracking is Script {
    function run() external returns (ProcessTracking) {
        vm.startBroadcast();
        ProcessTracking processTracking = new ProcessTracking();
        vm.stopBroadcast();
        return processTracking;
    }
}
