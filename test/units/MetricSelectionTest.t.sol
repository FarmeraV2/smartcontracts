// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {MetricSelection} from "../../src/MetricSelection.sol";

contract MetricSelectionTest is Test {
    MetricSelection metricSelection;

    function setUp() external {
        metricSelection = new MetricSelection();
    }

    // ============ Basic Registration Tests ============

    function testRegisterWithMultipleContextsForSameDataType() external {
        address package1 = address(0x1111);
        address package2 = address(0x2222);

        metricSelection.registerTrustPackage("temperature", "indoor", package1);
        metricSelection.registerTrustPackage("temperature", "outdoor", package2);

        assertEq(metricSelection.getTrustPackage("temperature", "indoor"), package1);
        assertEq(metricSelection.getTrustPackage("temperature", "outdoor"), package2);
    }

    function testRegisterAndGetTrustPackage() external {
        string memory dataType = "temperature";
        string memory context = "indoor";
        address trustPackageAddress = address(0x1234);

        metricSelection.registerTrustPackage(dataType, context, trustPackageAddress);

        address retrievedAddress = metricSelection.getTrustPackage(dataType, context);

        assertEq(retrievedAddress, trustPackageAddress);
    }

    function testRegisterWithMultipleDataTypesForSameContext() external {
        address package1 = address(0x1111);
        address package2 = address(0x2222);

        metricSelection.registerTrustPackage("temperature", "sensor_1", package1);
        metricSelection.registerTrustPackage("humidity", "sensor_1", package2);

        assertEq(metricSelection.getTrustPackage("temperature", "sensor_1"), package1);
        assertEq(metricSelection.getTrustPackage("humidity", "sensor_1"), package2);
    }

    // // ============ Overwrite Tests ============

    function testOverwriteExistingTrustPackage() external {
        string memory dataType = "temperature";
        string memory context = "indoor";
        address initialPackage = address(0x1111);
        address newPackage = address(0x2222);

        metricSelection.registerTrustPackage(dataType, context, initialPackage);

        vm.expectRevert(MetricSelection.MetricSelection__TrustPackageExisted.selector);

        metricSelection.registerTrustPackage(dataType, context, newPackage);
    }

    function testRegisterWithAddressZero() external {
        string memory dataType = "temperature";
        string memory context = "indoor";

        vm.expectRevert(MetricSelection.MetricSelection__InvalidAddress.selector);
        metricSelection.registerTrustPackage(dataType, context, address(0));
    }

    // // ============ Retrieval Tests ============

    function testGetNonExistentTrustPackageReturnsZeroAddress() external view {
        address result = metricSelection.getTrustPackage("nonexistent", "context");
        assertEq(result, address(0));
    }

    function testGetTrustPackageWithWrongContextReturnsZeroAddress() external {
        address package = address(0x1234);
        metricSelection.registerTrustPackage("type", "context1", package);

        address result = metricSelection.getTrustPackage("type", "context2");
        assertEq(result, address(0));
    }

    function testGetTrustPackageWithWrongDataTypeReturnsZeroAddress() external {
        address package = address(0x1234);
        metricSelection.registerTrustPackage("type1", "context", package);

        address result = metricSelection.getTrustPackage("type2", "context");
        assertEq(result, address(0));
    }

    // // ============ Event Tests ============

    function testRegisterEmitsTrustPackageRegisteredEvent() external {
        string memory dataType = "temperature";
        string memory context = "indoor";
        address trustPackageAddress = address(0x1234);

        bytes32 expectedKey = keccak256(abi.encodePacked(dataType, context));

        vm.expectEmit(true, false, false, false);
        emit MetricSelection.TrustPackageRegistered(expectedKey);

        metricSelection.registerTrustPackage(dataType, context, trustPackageAddress);
    }

    // // ============ Edge Cases ============

    function testRegisterWithEmptyDataType() external {
        address package = address(0x1234);

        vm.expectRevert(MetricSelection.MetricSelection__InvalidDataType.selector);

        metricSelection.registerTrustPackage("", "context", package);
    }

    function testRegisterWithEmptyContext() external {
        address package = address(0x1234);

        vm.expectRevert(MetricSelection.MetricSelection__InvalidDataType.selector);

        metricSelection.registerTrustPackage("type", "", package);
    }

    function testRegisterWithBothEmptyDataTypeAndContext() external {
        address package = address(0x1234);

        vm.expectRevert(MetricSelection.MetricSelection__InvalidDataType.selector);

        metricSelection.registerTrustPackage("", "", package);
    }

    function testRegisterWithSpecialCharactersInDataType() external {
        address package = address(0x1234);
        string memory specialType = "type!@#$%^&*()";
        metricSelection.registerTrustPackage(specialType, "context", package);
        assertEq(metricSelection.getTrustPackage(specialType, "context"), package);
    }

    function testRegisterWithSpecialCharactersInContext() external {
        address package = address(0x1234);
        string memory specialContext = "context!@#$%^&*()";
        metricSelection.registerTrustPackage("type", specialContext, package);
        assertEq(metricSelection.getTrustPackage("type", specialContext), package);
    }

    function testRegisterWithLongDataType() external {
        address package = address(0x1234);
        string memory longType =
            "a_very_long_data_type_that_contains_many_characters_to_test_if_it_still_works_correctly_in_the_system";
        metricSelection.registerTrustPackage(longType, "context", package);
        assertEq(metricSelection.getTrustPackage(longType, "context"), package);
    }

    function testRegisterWithLongContext() external {
        address package = address(0x1234);
        string memory longContext =
            "a_very_long_context_that_contains_many_characters_to_test_if_it_still_works_correctly_in_the_system";
        metricSelection.registerTrustPackage("type", longContext, package);
        assertEq(metricSelection.getTrustPackage("type", longContext), package);
    }
}
