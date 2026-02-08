// // SPDX-License-Identifier: MIT

// pragma solidity >=0.8.30;

// import {Test} from "forge-std/Test.sol";
// import {TrustComputation} from "../../src/TrustComputation.sol";
// import {MetricSelection} from "../../src/MetricSelection.sol";
// import {TrustPackage} from "../../src/interfaces/TrustPackage.sol";
// import {MockTrustPackage} from "../mocks/MockTrustPackage.sol";
// import {
//     DeployTrustComputation
// } from "../../script/DeployTrustComputation.s.sol";

// contract TrustComputationTest is Test {
//     TrustComputation trustComputation;
//     MetricSelection metricSelection;
//     MockTrustPackage mockTrustPackage;

//     address constant TRUST_PACKAGE_REGISTRY = address(0x1);
//     address constant MOCK_PACKAGE_ADDRESS = address(0x2);

//     bytes32 constant IDENTIFIER = bytes32(abi.encodePacked("ID"));
//     uint64 constant LOG_ID = 12345;
//     uint128 constant TRUST_SCORE = 95;

//     function setUp() external {
//         DeployTrustComputation deployer = new DeployTrustComputation();
//         trustComputation = deployer.run();
//         metricSelection = trustComputation.getMetricSelection();
//         mockTrustPackage = new MockTrustPackage(TRUST_SCORE);
//     }

//     function testProcessDataSuccessfullyProcessesData() public {
//         // Register the trust package
//         metricSelection.registerTrustPackage(
//             "TYPE_A",
//             "CONTEXT_1",
//             address(mockTrustPackage)
//         );

//         // Process data
//         bytes memory testData = abi.encode("test data");
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_A",
//             "CONTEXT_1",
//             testData
//         );

//         // Verify the record was stored
//         (, , uint128 trustScore, uint256 timestamp) = trustComputation
//             .getTrustRecord(IDENTIFIER, LOG_ID);
//         assertEq(trustScore, TRUST_SCORE);
//         assertEq(timestamp, block.timestamp);
//     }

//     function testProcessDataRevertsWhenNoTrustPackageFound() public {
//         bytes memory testData = abi.encode("test data");
//         vm.expectRevert(
//             TrustComputation.TrustComputation__NoTrustPackage.selector
//         );
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "UNKNOWN_TYPE",
//             "UNKNOWN_CONTEXT",
//             testData
//         );
//     }

//     function testProcessDataStoresTrustRecordWithCorrectData() public {
//         uint128 customScore = 75;
//         MockTrustPackage customPackage = new MockTrustPackage(customScore);
//         metricSelection.registerTrustPackage(
//             "TYPE_B",
//             "CONTEXT_2",
//             address(customPackage)
//         );

//         bytes memory testData = abi.encode("different data");
//         uint256 blockTimestamp = block.timestamp;
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_B",
//             "CONTEXT_2",
//             testData
//         );

//         (, , uint128 trustScore, uint256 timestamp) = trustComputation
//             .getTrustRecord(IDENTIFIER, LOG_ID);
//         assertEq(trustScore, customScore);
//         assertEq(timestamp, blockTimestamp);
//     }

//     function testProcessDataUpdatesExistingRecord() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_C",
//             "CONTEXT_3",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");
//         uint64 sameLogId = 999;

//         // Process first time
//         trustComputation.processData(
//             IDENTIFIER,
//             sameLogId,
//             "TYPE_C",
//             "CONTEXT_3",
//             testData
//         );
//         (, , uint128 firstScore, ) = trustComputation.getTrustRecord(
//             IDENTIFIER,
//             sameLogId
//         );
//         assertEq(firstScore, TRUST_SCORE);

//         // Move time forward
//         vm.warp(block.timestamp + 1000);

//         // Create new package with different score
//         MockTrustPackage newPackage = new MockTrustPackage(50);
//         metricSelection.registerTrustPackage(
//             "TYPE_D",
//             "CONTEXT_3",
//             address(newPackage)
//         );

//         vm.expectRevert(
//             TrustComputation.TrustComputation__IdAlreadyProcessed.selector
//         );

//         // Process again with same logId
//         trustComputation.processData(
//             IDENTIFIER,
//             sameLogId,
//             "TYPE_C",
//             "CONTEXT_3",
//             testData
//         );
//     }

//     function testProcessDataWithEmptyData() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_D",
//             "CONTEXT_4",
//             address(mockTrustPackage)
//         );

//         bytes memory emptyData = "";
//         vm.expectRevert(
//             TrustComputation.TrustComputation__InvalidData.selector
//         );
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_D",
//             "CONTEXT_4",
//             emptyData
//         );
//     }

//     function testProcessDataWithLargeData() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_E",
//             "CONTEXT_5",
//             address(mockTrustPackage)
//         );

//         // Create large data payload
//         bytes memory largeData = new bytes(1000);
//         for (uint256 i = 0; i < 1000; i++) {
//             largeData[i] = bytes1(uint8(i % 256));
//         }

//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_E",
//             "CONTEXT_5",
//             largeData
//         );

//         (, , uint128 trustScore, ) = trustComputation.getTrustRecord(
//             IDENTIFIER,
//             LOG_ID
//         );
//         assertEq(trustScore, TRUST_SCORE);
//     }

//     function testProcessDataWithDifferentLogIds() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_F",
//             "CONTEXT_6",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");

//         // Process multiple log IDs
//         for (uint64 i = 0; i < 5; i++) {
//             trustComputation.processData(
//                 IDENTIFIER,
//                 i,
//                 "TYPE_F",
//                 "CONTEXT_6",
//                 testData
//             );
//             (, , uint128 trustScore, ) = trustComputation.getTrustRecord(
//                 IDENTIFIER,
//                 i
//             );
//             assertEq(trustScore, TRUST_SCORE);
//         }
//     }

//     function testProcessDataEmitsTrustProcessedEvent() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_G",
//             "CONTEXT_7",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("event test");
//         vm.expectEmit(true, true, false, true);
//         emit TrustComputation.TrustProcessed(IDENTIFIER, LOG_ID, TRUST_SCORE);
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_G",
//             "CONTEXT_7",
//             testData
//         );
//     }

//     // // ============ Edge Cases ============

//     function testProcessDataTimestampIsBlockTimestamp() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_K",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");

//         uint256 expectedTimestamp = block.timestamp;
//         trustComputation.processData(
//             IDENTIFIER,
//             LOG_ID,
//             "TYPE_K",
//             "CONTEXT",
//             testData
//         );

//         (, , , uint256 timestamp) = trustComputation.getTrustRecord(
//             IDENTIFIER,
//             LOG_ID
//         );
//         assertEq(timestamp, expectedTimestamp);
//     }

//     function testProcessDataTimestampChangesWhenBlockTimestampChanges() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_L",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");

//         trustComputation.processData(
//             IDENTIFIER,
//             111,
//             "TYPE_L",
//             "CONTEXT",
//             testData
//         );
//         (, , , uint256 timestamp1) = trustComputation.getTrustRecord(
//             IDENTIFIER,
//             111
//         );

//         vm.warp(block.timestamp + 3600); // Warp 1 hour forward

//         trustComputation.processData(
//             IDENTIFIER,
//             222,
//             "TYPE_L",
//             "CONTEXT",
//             testData
//         );
//         (, , , uint256 timestamp2) = trustComputation.getTrustRecord(
//             IDENTIFIER,
//             222
//         );

//         assertNotEq(timestamp1, timestamp2);
//         assertEq(timestamp2 - timestamp1, 3600);
//     }

//     // ============ getTrustRecords Tests ============

//     function testGetTrustRecordsReturnsEmptyArraysForEmptyInput() public {
//         uint64[] memory emptyLogIds = new uint64[](0);

//         (
//             uint128[] memory trustScores,
//             uint256[] memory timestamps
//         ) = trustComputation.getTrustRecords(IDENTIFIER, emptyLogIds);

//         assertEq(trustScores.length, 0);
//         assertEq(timestamps.length, 0);
//     }

//     function testGetTrustRecordsSingleRecord() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_M",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");
//         uint64 testLogId = 100;

//         trustComputation.processData(
//             IDENTIFIER,
//             testLogId,
//             "TYPE_M",
//             "CONTEXT",
//             testData
//         );

//         uint64[] memory logIds = new uint64[](1);
//         logIds[0] = testLogId;

//         (
//             uint128[] memory trustScores,
//             uint256[] memory timestamps
//         ) = trustComputation.getTrustRecords(IDENTIFIER, logIds);

//         assertEq(trustScores.length, 1);
//         assertEq(timestamps.length, 1);
//         assertEq(trustScores[0], TRUST_SCORE);
//         assertEq(timestamps[0], block.timestamp);
//     }

//     function testGetTrustRecordsMultipleRecords() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_N",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");
//         uint256 recordCount = 5;

//         // Process multiple records
//         for (uint64 i = 0; i < recordCount; i++) {
//             trustComputation.processData(
//                 IDENTIFIER,
//                 i,
//                 "TYPE_N",
//                 "CONTEXT",
//                 testData
//             );
//         }

//         uint64[] memory logIds = new uint64[](recordCount);
//         for (uint64 i = 0; i < recordCount; i++) {
//             logIds[i] = i;
//         }

//         (
//             uint128[] memory trustScores,
//             uint256[] memory timestamps
//         ) = trustComputation.getTrustRecords(IDENTIFIER, logIds);

//         assertEq(trustScores.length, recordCount);
//         assertEq(timestamps.length, recordCount);

//         // Verify all records
//         for (uint256 i = 0; i < recordCount; i++) {
//             assertEq(trustScores[i], TRUST_SCORE);
//             assertEq(timestamps[i], block.timestamp);
//         }
//     }

//     function testGetTrustRecordsWithNonExistentRecords() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_O",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");

//         // Process only logId 10
//         trustComputation.processData(
//             IDENTIFIER,
//             10,
//             "TYPE_O",
//             "CONTEXT",
//             testData
//         );

//         uint64[] memory logIds = new uint64[](3);

//         logIds[0] = 10;
//         logIds[1] = 20;
//         logIds[2] = 30;

//         (
//             uint128[] memory trustScores,
//             uint256[] memory timestamps
//         ) = trustComputation.getTrustRecords(IDENTIFIER, logIds);

//         assertEq(trustScores.length, 3);
//         assertEq(timestamps.length, 3);

//         // First record should have values
//         assertEq(trustScores[0], TRUST_SCORE);
//         assertEq(timestamps[0], block.timestamp);

//         // Non-existent records should return 0
//         assertEq(trustScores[1], 0);
//         assertEq(timestamps[1], 0);
//         assertEq(trustScores[2], 0);
//         assertEq(timestamps[2], 0);
//     }

//     function testGetTrustRecordsPreservesOrder() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_Q",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");

//         trustComputation.processData(
//             IDENTIFIER,
//             100,
//             "TYPE_Q",
//             "CONTEXT",
//             testData
//         );
//         trustComputation.processData(
//             IDENTIFIER,
//             200,
//             "TYPE_Q",
//             "CONTEXT",
//             testData
//         );
//         trustComputation.processData(
//             IDENTIFIER,
//             300,
//             "TYPE_Q",
//             "CONTEXT",
//             testData
//         );

//         // Query in non-sequential order
//         uint64[] memory logIds = new uint64[](3);
//         logIds[0] = 300;
//         logIds[1] = 100;
//         logIds[2] = 200;

//         (uint128[] memory trustScores, ) = trustComputation.getTrustRecords(
//             IDENTIFIER,
//             logIds
//         );

//         // Should preserve the order requested, not storage order
//         assertEq(trustScores[0], TRUST_SCORE);
//         assertEq(trustScores[1], TRUST_SCORE);
//         assertEq(trustScores[2], TRUST_SCORE);
//     }

//     function testGetTrustRecordsWithDuplicateIds() public {
//         metricSelection.registerTrustPackage(
//             "TYPE_R",
//             "CONTEXT",
//             address(mockTrustPackage)
//         );

//         bytes memory testData = abi.encode("data");
//         trustComputation.processData(
//             IDENTIFIER,
//             50,
//             "TYPE_R",
//             "CONTEXT",
//             testData
//         );

//         // Query same ID multiple times
//         uint64[] memory logIds = new uint64[](4);
//         logIds[0] = 50;
//         logIds[1] = 50;
//         logIds[2] = 50;
//         logIds[3] = 50;

//         (
//             uint128[] memory trustScores,
//             uint256[] memory timestamps
//         ) = trustComputation.getTrustRecords(IDENTIFIER, logIds);

//         assertEq(trustScores.length, 4);
//         assertEq(timestamps.length, 4);

//         // All should return the same values
//         for (uint256 i = 0; i < 4; i++) {
//             assertEq(trustScores[i], TRUST_SCORE);
//             assertEq(timestamps[i], block.timestamp);
//         }
//     }
// }
