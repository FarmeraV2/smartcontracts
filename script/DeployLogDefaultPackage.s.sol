// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {LogDefaultPackage} from "../src/trustworthiness/packages/LogDefaultPackage.sol";

contract DeployLogDefaultPackage is Script {
    function run() external returns (LogDefaultPackage) {
        vm.startBroadcast();

        LogDefaultPackage deployed = new LogDefaultPackage();

        vm.stopBroadcast();
        return deployed;
    }
}
