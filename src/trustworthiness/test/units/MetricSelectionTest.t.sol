// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MetricSelection} from "../../MetricSelection.sol";

contract MetricSelectionTest is Test {
    MetricSelection metricSelection;

    function setUp() external {
        metricSelection = new MetricSelection();
    }

    function test_registerAndGetTrustPackage() external {
        address pkg = makeAddr("package");
        metricSelection.registerTrustPackage("log", "default", pkg);
        assertEq(metricSelection.getTrustPackage("log", "default"), pkg);
    }

    function test_revertOnDuplicateRegistration() external {
        address pkg = makeAddr("package");
        metricSelection.registerTrustPackage("log", "default", pkg);
        vm.expectRevert(MetricSelection.MetricSelection__TrustPackageExisted.selector);
        metricSelection.registerTrustPackage("log", "default", makeAddr("other"));
    }

    function test_revertOnZeroAddress() external {
        vm.expectRevert(MetricSelection.MetricSelection__InvalidAddress.selector);
        metricSelection.registerTrustPackage("log", "default", address(0));
    }

    function test_revertOnEmptyDataType() external {
        vm.expectRevert(MetricSelection.MetricSelection__InvalidDataType.selector);
        metricSelection.registerTrustPackage("", "default", makeAddr("package"));
    }

    function test_getNonExistentPackageReturnsZero() external view {
        assertEq(metricSelection.getTrustPackage("unknown", "ctx"), address(0));
    }
}
