// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {LogAuditorPackage} from "../src/trustworthiness/packages/LogAuditorPackage.sol";

contract DeployLogAuditorPackage is Script {
    function run() external returns (LogAuditorPackage) {
        return run(address(0));
    }

    function run(address auditorRegistry) public returns (LogAuditorPackage) {
        vm.startBroadcast();

        LogAuditorPackage deployed = new LogAuditorPackage(auditorRegistry);

        vm.stopBroadcast();
        return deployed;
    }
}
