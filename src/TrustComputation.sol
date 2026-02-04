// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {MetricSelection} from "./MetricSelection.sol";
import {TrustPackage} from "./interfaces/TrustPackage.sol";

contract TrustComputation {
    error TrustComputation__NoTrustPackage();

    struct TrustRecord {
        uint trustScore;
        uint timestamp;
    }

    MetricSelection private s_metricSelection;
    mapping(uint64 logId => TrustRecord) public trustRecords;

    event TrustProcessed(uint64 logId, uint trustScore);

    constructor(address metricSelectionAddress) {
        s_metricSelection = MetricSelection(metricSelectionAddress);
    }

    function processData(
        uint64 logId,
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
        uint score = TrustPackage(trustPackageAddress).computeTrustScore(data);
        trustRecords[logId] = TrustRecord({
            trustScore: score,
            timestamp: block.timestamp
        });
    }
}
