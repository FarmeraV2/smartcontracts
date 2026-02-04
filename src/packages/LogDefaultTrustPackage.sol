// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../interfaces/TrustPackage.sol";

contract LogDefaultTrustPackage is TrustPackage {
    uint256 constant MAX_DISTANCE = 100_000; // ~100 meters in 1e6 scaled lat/lng
    uint256 constant MAX_IMAGE_COUNT = 1;
    uint256 constant MAX_VIDEO_COUNT = 1;

    uint256 constant SCALE = 100;
    uint256 constant WEIGHT_SPATIAL_PLAUSIBILITY = 30;
    uint256 constant WEIGHT_EVIDENCE_COMPLETENESS = 50;
    uint256 constant WEIGHT_STEP_COMPLIANCE = 20;

    struct Location {
        int256 latitude; // lat * 1e6
        int256 longitude; // lng * 1e6
    }

    struct LogData {
        bool isCompliant;
        bool verified;
        uint256 imageCount;
        uint256 videoCount;
        Location logLocation;
        Location plotLocation;
    }

    function computeTrustScore(
        bytes calldata payload
    ) external pure returns (uint256) {
        LogData memory logData = abi.decode(payload, (LogData));

        // provenance
        if (!logData.verified) {
            return 0;
        }

        // spatial plausibility
        uint256 Tsp = 0;
        uint256 dist = _distance(logData.plotLocation, logData.logLocation);
        if (dist <= MAX_DISTANCE) {
            Tsp = ((MAX_DISTANCE - dist) * SCALE) / MAX_DISTANCE;
        }

        // evidence completeness
        uint256 Tec = _min(
            (MAX_IMAGE_COUNT *
                logData.imageCount +
                MAX_VIDEO_COUNT *
                logData.videoCount) / (MAX_IMAGE_COUNT + MAX_VIDEO_COUNT),
            1
        ) * SCALE;

        // step compliance
        uint256 Tsc = logData.isCompliant ? SCALE : 0;

        return
            (WEIGHT_SPATIAL_PLAUSIBILITY *
                Tsp +
                WEIGHT_EVIDENCE_COMPLETENESS *
                Tec +
                WEIGHT_STEP_COMPLIANCE *
                Tsc) / SCALE;
    }

    function _distance(
        Location memory a,
        Location memory b
    ) internal pure returns (uint256) {
        int256 latDiff = a.latitude - b.latitude;
        int256 lngDiff = a.longitude - b.longitude;
        return uint256(latDiff * latDiff + lngDiff * lngDiff);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
