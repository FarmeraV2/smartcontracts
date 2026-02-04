// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {MetricSelection} from "./MetricSelection.sol";
import {TrustPackage} from "./interfaces/TrustPackage.sol";

contract TrustComputation {
    error TrustComputation__NoTrustPackage();
    error TrustComputation__IdAlreadyProcessed();
    error TrustComputation__InvalidData();

    struct TrustRecord {
        uint256 trustScore;
        uint256 timestamp;
    }

    MetricSelection private s_metricSelection;
    mapping(uint64 logId => TrustRecord) private s_trustRecords;

    event TrustProcessed(uint64 indexed logId, uint256 trustScore);

    constructor(address metricSelectionAddress) {
        s_metricSelection = MetricSelection(metricSelectionAddress);
    }

    function processData(uint64 logId, string memory dataType, string memory context, bytes calldata data) external {
        address trustPackageAddress = s_metricSelection.getTrustPackage(dataType, context);
        if (trustPackageAddress == address(0)) {
            revert TrustComputation__NoTrustPackage();
        }

        if (s_trustRecords[logId].timestamp != 0) {
            revert TrustComputation__IdAlreadyProcessed();
        }

        if (data.length == 0) {
            revert TrustComputation__InvalidData();
        }

        uint256 score = TrustPackage(trustPackageAddress).computeTrustScore(data);
        s_trustRecords[logId] = TrustRecord({trustScore: score, timestamp: block.timestamp});

        emit TrustProcessed(logId, score);
    }

    function getTrustRecord(uint64 logId) external view returns (uint64, uint256 trustScore, uint256 timestamp) {
        TrustRecord memory record = s_trustRecords[logId];
        return (logId, record.trustScore, record.timestamp);
    }

    function getTrustRecords(uint64[] memory logIds) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory trustScore = new uint256[](logIds.length);
        uint256[] memory timestamp = new uint256[](logIds.length);
        uint32 i = 0;
        for (; i < logIds.length; i++) {
            trustScore[i] = s_trustRecords[logIds[i]].trustScore;
            timestamp[i] = s_trustRecords[logIds[i]].timestamp;
        }
        return (trustScore, timestamp);
    }

    function getMetricSelection() external view returns (MetricSelection) {
        return s_metricSelection;
    }
}
