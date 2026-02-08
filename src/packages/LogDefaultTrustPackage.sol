// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../interfaces/TrustPackage.sol";

contract LogDefaultTrustPackage is TrustPackage {
    uint128 constant MAX_DISTANCE = 100_000; // ~100 meters in 1e6 scaled lat/lng
    uint128 constant MAX_IMAGE_COUNT = 1;
    uint128 constant MAX_VIDEO_COUNT = 1;

    uint128 constant SCALE = 100;
    uint128 constant WEIGHT_PROVENANCE = 50;
    uint128 constant WEIGHT_SPATIAL_PLAUSIBILITY = 30;
    uint128 constant WEIGHT_EVIDENCE_COMPLETENESS = 20;
    // uint128 constant WEIGHT_STEP_COMPLIANCE = 20;

    struct Location {
        int128 latitude; // lat * 1e6
        int128 longitude; // lng * 1e6
    }

    struct LogData {
        bool verified;
        uint128 imageCount;
        uint128 videoCount;
        Location logLocation;
        Location plotLocation;
    }

    function computeTrustScore(
        bytes calldata payload
    ) external pure returns (uint128) {
        LogData memory logData = abi.decode(payload, (LogData));

        // provenance
        uint128 Tp = 0;
        if (logData.verified) {
            Tp = 1 * SCALE;
        }

        // spatial plausibility
        uint128 Tsp = 0;
        uint128 dist = _distance(logData.plotLocation, logData.logLocation);
        if (dist <= MAX_DISTANCE) {
            Tsp = ((MAX_DISTANCE - dist) * SCALE) / MAX_DISTANCE;
        }

        // evidence completeness
        uint128 Tec = _min(
            (MAX_IMAGE_COUNT *
                logData.imageCount +
                MAX_VIDEO_COUNT *
                logData.videoCount) / (MAX_IMAGE_COUNT + MAX_VIDEO_COUNT),
            1
        ) * SCALE;

        // step compliance
        // uint128 Tsc = logData.isCompliant ? SCALE : 0;

        return
            (WEIGHT_SPATIAL_PLAUSIBILITY *
                Tsp +
                WEIGHT_EVIDENCE_COMPLETENESS *
                Tec +
                WEIGHT_PROVENANCE *
                Tp) / SCALE;
    }

    function _distance(
        Location memory a,
        Location memory b
    ) internal pure returns (uint128) {
        int128 latDiff = a.latitude - b.latitude;
        int128 lngDiff = a.longitude - b.longitude;
        return uint128(latDiff * latDiff + lngDiff * lngDiff);
    }

    function _min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }
}
