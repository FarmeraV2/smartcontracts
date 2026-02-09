// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import {Test} from "forge-std/Test.sol";
import {TrustComputation} from "../../src/TrustComputation.sol";
import {MetricSelection} from "../../src/MetricSelection.sol";
import {MockTrustPackage} from "../mocks/MockTrustPackage.sol";

contract TrustComputationTest is Test {
    TrustComputation trustComputation;
    MetricSelection metricSelection;
    MockTrustPackage mockPackage;

    bytes32 constant IDENTIFIER = keccak256("farm-1");
    uint64 constant LOG_ID = 1;

    function setUp() external {
        metricSelection = new MetricSelection();
        mockPackage = new MockTrustPackage(85);
        metricSelection.registerTrustPackage("log", "default", address(mockPackage));
        trustComputation = new TrustComputation(address(metricSelection));
    }

    function test_processDataSuccessfully() external {
        trustComputation.processData(IDENTIFIER, LOG_ID, "log", "default", abi.encode(uint256(1)));
        (,, uint128 score, uint256 ts) = trustComputation.getTrustRecord(IDENTIFIER, LOG_ID);
        assertEq(score, 85);
        assertEq(ts, block.timestamp);
    }

    function test_revertOnNoTrustPackage() external {
        vm.expectRevert(TrustComputation.TrustComputation__NoTrustPackage.selector);
        trustComputation.processData(IDENTIFIER, LOG_ID, "unknown", "ctx", abi.encode(uint256(1)));
    }

    function test_revertOnDuplicateId() external {
        trustComputation.processData(IDENTIFIER, LOG_ID, "log", "default", abi.encode(uint256(1)));
        vm.expectRevert(
            abi.encodeWithSelector(TrustComputation.TrustComputation__IdAlreadyProcessed.selector, IDENTIFIER, LOG_ID)
        );
        trustComputation.processData(IDENTIFIER, LOG_ID, "log", "default", abi.encode(uint256(1)));
    }

    function test_revertOnEmptyData() external {
        vm.expectRevert(TrustComputation.TrustComputation__InvalidData.selector);
        trustComputation.processData(IDENTIFIER, LOG_ID, "log", "default", "");
    }

    function test_getTrustRecordsBatch() external {
        trustComputation.processData(IDENTIFIER, 1, "log", "default", abi.encode(uint256(1)));
        trustComputation.processData(IDENTIFIER, 2, "log", "default", abi.encode(uint256(1)));

        uint64[] memory ids = new uint64[](2);
        ids[0] = 1;
        ids[1] = 2;

        (uint128[] memory scores, uint256[] memory timestamps) = trustComputation.getTrustRecords(IDENTIFIER, ids);
        assertEq(scores.length, 2);
        assertEq(scores[0], 85);
        assertEq(scores[1], 85);
        assertGt(timestamps[0], 0);
        assertGt(timestamps[1], 0);
    }
}
