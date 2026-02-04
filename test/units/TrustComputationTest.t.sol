// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {Test} from "forge-std/Test.sol";
import {TrustComputation} from "../../src/TrustComputation.sol";
import {MetricSelection} from "../../src/MetricSelection.sol";
import {TrustPackage} from "../../src/interfaces/TrustPackage.sol";
import {MockTrustPackage} from "../mocks/MockTrustPackage.sol";
import {DeployTrustComputation} from "../../script/DeployTrustComputation.s.sol";

contract TrustComputationTest is Test {
    TrustComputation trustComputation;
    MetricSelection metricSelection;
    MockTrustPackage mockTrustPackage;

    address constant TRUST_PACKAGE_REGISTRY = address(0x1);
    address constant MOCK_PACKAGE_ADDRESS = address(0x2);

    uint64 constant LOG_ID = 12345;
    uint256 constant TRUST_SCORE = 95;

    event TrustProcessed(uint64 logId, uint256 trustScore);

    function setUp() external {
        DeployTrustComputation deployer = new DeployTrustComputation();
        trustComputation = deployer.run();
        metricSelection = trustComputation.getMetricSelection();
        mockTrustPackage = new MockTrustPackage(TRUST_SCORE);
    }

    function testProcessDataSuccessfullyProcessesData() public {
        // Register the trust package
        metricSelection.registerTrustPackage("TYPE_A", "CONTEXT_1", address(mockTrustPackage));

        // Process data
        bytes memory testData = abi.encode("test data");
        trustComputation.processData(LOG_ID, "TYPE_A", "CONTEXT_1", testData);

        // Verify the record was stored
        (uint256 trustScore, uint256 timestamp) = trustComputation.getTrustRecord(LOG_ID);
        assertEq(trustScore, TRUST_SCORE);
        assertEq(timestamp, block.timestamp);
    }

    function testProcessDataRevertsWhenNoTrustPackageFound() public {
        bytes memory testData = abi.encode("test data");
        vm.expectRevert(TrustComputation.TrustComputation__NoTrustPackage.selector);
        trustComputation.processData(LOG_ID, "UNKNOWN_TYPE", "UNKNOWN_CONTEXT", testData);
    }

    function testProcessDataStoresTrustRecordWithCorrectData() public {
        uint256 customScore = 75;
        MockTrustPackage customPackage = new MockTrustPackage(customScore);
        metricSelection.registerTrustPackage("TYPE_B", "CONTEXT_2", address(customPackage));

        bytes memory testData = abi.encode("different data");
        uint256 blockTimestamp = block.timestamp;
        trustComputation.processData(LOG_ID, "TYPE_B", "CONTEXT_2", testData);

        (uint256 trustScore, uint256 timestamp) = trustComputation.getTrustRecord(LOG_ID);
        assertEq(trustScore, customScore);
        assertEq(timestamp, blockTimestamp);
    }

    function testProcessDataUpdatesExistingRecord() public {
        metricSelection.registerTrustPackage("TYPE_C", "CONTEXT_3", address(mockTrustPackage));

        bytes memory testData = abi.encode("data");
        uint64 sameLogId = 999;

        // Process first time
        trustComputation.processData(sameLogId, "TYPE_C", "CONTEXT_3", testData);
        (uint256 firstScore,) = trustComputation.getTrustRecord(sameLogId);
        assertEq(firstScore, TRUST_SCORE);

        // Move time forward
        vm.warp(block.timestamp + 1000);

        // Create new package with different score
        MockTrustPackage newPackage = new MockTrustPackage(50);
        metricSelection.registerTrustPackage("TYPE_D", "CONTEXT_3", address(newPackage));

        vm.expectRevert(TrustComputation.TrustComputation__IdAlreadyProcessed.selector);

        // Process again with same logId
        trustComputation.processData(sameLogId, "TYPE_C", "CONTEXT_3", testData);
    }

    function testProcessDataWithEmptyData() public {
        metricSelection.registerTrustPackage("TYPE_D", "CONTEXT_4", address(mockTrustPackage));

        bytes memory emptyData = "";
        vm.expectRevert(TrustComputation.TrustComputation__InvalidData.selector);
        trustComputation.processData(LOG_ID, "TYPE_D", "CONTEXT_4", emptyData);
    }

    function testProcessDataWithLargeData() public {
        metricSelection.registerTrustPackage("TYPE_E", "CONTEXT_5", address(mockTrustPackage));

        // Create large data payload
        bytes memory largeData = new bytes(1000);
        for (uint256 i = 0; i < 1000; i++) {
            largeData[i] = bytes1(uint8(i % 256));
        }

        trustComputation.processData(LOG_ID, "TYPE_E", "CONTEXT_5", largeData);

        (uint256 trustScore,) = trustComputation.getTrustRecord(LOG_ID);
        assertEq(trustScore, TRUST_SCORE);
    }

    function testProcessDataWithDifferentLogIds() public {
        metricSelection.registerTrustPackage("TYPE_F", "CONTEXT_6", address(mockTrustPackage));

        bytes memory testData = abi.encode("data");

        // Process multiple log IDs
        for (uint64 i = 0; i < 5; i++) {
            trustComputation.processData(i, "TYPE_F", "CONTEXT_6", testData);
            (uint256 trustScore,) = trustComputation.getTrustRecord(i);
            assertEq(trustScore, TRUST_SCORE);
        }
    }

    function testProcessDataEmitsTrustProcessedEvent() public {
        metricSelection.registerTrustPackage("TYPE_G", "CONTEXT_7", address(mockTrustPackage));

        bytes memory testData = abi.encode("event test");
        vm.expectEmit(true, false, false, true);
        emit TrustComputation.TrustProcessed(LOG_ID, TRUST_SCORE);
        trustComputation.processData(LOG_ID, "TYPE_G", "CONTEXT_7", testData);
    }

    // // ============ Edge Cases ============

    function testProcessDataTimestampIsBlockTimestamp() public {
        metricSelection.registerTrustPackage("TYPE_K", "CONTEXT", address(mockTrustPackage));

        bytes memory testData = abi.encode("data");

        uint256 expectedTimestamp = block.timestamp;
        trustComputation.processData(LOG_ID, "TYPE_K", "CONTEXT", testData);

        (, uint256 timestamp) = trustComputation.getTrustRecord(LOG_ID);
        assertEq(timestamp, expectedTimestamp);
    }

    function testProcessDataTimestampChangesWhenBlockTimestampChanges() public {
        metricSelection.registerTrustPackage("TYPE_L", "CONTEXT", address(mockTrustPackage));

        bytes memory testData = abi.encode("data");

        trustComputation.processData(111, "TYPE_L", "CONTEXT", testData);
        (, uint256 timestamp1) = trustComputation.getTrustRecord(111);

        vm.warp(block.timestamp + 3600); // Warp 1 hour forward

        trustComputation.processData(222, "TYPE_L", "CONTEXT", testData);
        (, uint256 timestamp2) = trustComputation.getTrustRecord(222);

        assertNotEq(timestamp1, timestamp2);
        assertEq(timestamp2 - timestamp1, 3600);
    }
}
