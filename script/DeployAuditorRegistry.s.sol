// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {AuditorHelper} from "./AuditorHelper.s.sol";
import {AuditorRegistry} from "../src/auditor/AuditorRegistry.sol";

contract DeployAuditorRegistry is Script {
    function run() external returns (AuditorRegistry) {
        AuditorHelper helper = new AuditorHelper();
        AuditorHelper.Config memory config = helper.getConfig();

        vm.startBroadcast();
        AuditorRegistry auditorRegistry = new AuditorRegistry(config.priceFeed);
        vm.stopBroadcast();
        return auditorRegistry;
    }
}
