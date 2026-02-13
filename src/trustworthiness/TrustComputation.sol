// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

import {MetricSelection} from "./MetricSelection.sol";
import {TrustPackage} from "./interfaces/TrustPackage.sol";

contract TrustComputation {
    error TrustComputation__NoTrustPackage();
    error TrustComputation__IdAlreadyProcessed(bytes32, uint64);
    error TrustComputation__InvalidData();

    struct TrustRecord {
        bool accept;
        uint128 trustScore;
        uint256 timestamp;
    }

    MetricSelection private s_metricSelection;

    mapping(bytes32 => mapping(uint64 => TrustRecord)) private s_trustRecords;

    event TrustProcessed(
        bytes32 indexed identifier,
        uint64 indexed id,
        bool accept,
        uint128 trustScore
    );

    constructor(address metricSelectionAddress) {
        s_metricSelection = MetricSelection(metricSelectionAddress);
    }

    function processData(
        bytes32 identifier,
        uint64 id,
        string memory dataType,
        string memory context,
        bytes calldata data
    ) external {
        address trustPackageAddress = s_metricSelection.getTrustPackage(
            dataType,
            context
        );
        if (trustPackageAddress == address(0)) {
            revert TrustComputation__NoTrustPackage();
        }

        if (s_trustRecords[identifier][id].timestamp != 0) {
            revert TrustComputation__IdAlreadyProcessed(identifier, id);
        }

        if (data.length == 0) {
            revert TrustComputation__InvalidData();
        }

        (bool accept, uint128 score) = TrustPackage(trustPackageAddress)
            .computeTrustScore(data);

        s_trustRecords[identifier][id] = TrustRecord({
            accept: accept,
            trustScore: score,
            timestamp: block.timestamp
        });

        emit TrustProcessed(identifier, id, accept, score);
    }

    function getTrustRecord(
        bytes32 identifier,
        uint64 id
    ) external view returns (bytes32, uint64, TrustRecord memory) {
        TrustRecord memory record = s_trustRecords[identifier][id];
        return (identifier, id, record);
    }

    function getTrustRecords(
        bytes32 identifier,
        uint64[] calldata ids
    ) external view returns (bytes32, uint64[] memory, TrustRecord[] memory) {
        uint256 length = ids.length;
        TrustRecord[] memory records = new TrustRecord[](length);

        uint256 i = 0;
        for (i; i < length; i++) {
            TrustRecord memory record = s_trustRecords[identifier][ids[i]];
            records[i] = record;
        }

        return (identifier, ids, records);
    }

    function getMetricSelection() external view returns (MetricSelection) {
        return s_metricSelection;
    }
}
