// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../interfaces/TrustPackage.sol";
import {AuditorRegistry} from "../../auditor/AuditorRegistry.sol";

contract LogAuditorPackage is TrustPackage {
    uint128 constant SCALE = 100;
    uint128 constant MAX_DISTANCE = 100_000; // ~100 meters in 1e6 scaled lat/lng
    uint128 constant MAX_IMAGE_COUNT = 1;
    uint128 constant MAX_VIDEO_COUNT = 1;
    uint128 constant WEIGHT_CONSENSUS = 40;
    uint128 constant WEIGHT_CONSENSUS_STRENGTH = 15;
    uint128 constant WEIGHT_SPATIAL = 25;
    uint128 constant WEIGHT_EVIDENCE = 20;
    uint128 constant ACCEPT_SCORE = 70;

    struct Location {
        int128 latitude; // lat * 1e6
        int128 longitude; // lng * 1e6
    }

    struct LogAuditorData {
        bytes32 identifier;
        uint64 id;
        uint128 auditorCount; // number of auditors who voted
        uint128 minAuditors; // minimum required auditors
        uint128 imageCount;
        uint128 videoCount;
        Location logLocation;
        Location plotLocation;
    }

    AuditorRegistry private s_auditorRegistry;

    constructor(address auditorRegistry) {
        s_auditorRegistry = AuditorRegistry(auditorRegistry);
    }

    function computeTrustScore(
        bytes calldata payload
    ) external view returns (bool, uint128) {
        LogAuditorData memory data = abi.decode(payload, (LogAuditorData));

        bool verificationResult = s_auditorRegistry.getVerificationResult(
            data.identifier,
            data.id
        );

        // Consensus score: the reputation-weighted vote outcome
        uint128 Tc = (verificationResult ? 1 : 0) * SCALE;

        // Consensus strength: how many auditors participated relative to minimum
        uint128 Tcs = _min(
            (data.auditorCount * SCALE) / _max(data.minAuditors, 1),
            SCALE
        );

        // Spatial plausibility: distance-based score
        uint128 Tsp = 0;
        uint128 dist = _distance(data.plotLocation, data.logLocation);
        if (dist <= MAX_DISTANCE) {
            Tsp = ((MAX_DISTANCE - dist) * SCALE) / MAX_DISTANCE;
        }

        // Evidence completeness
        uint128 Te = _min(
            (MAX_IMAGE_COUNT *
                data.imageCount +
                MAX_VIDEO_COUNT *
                data.videoCount) / _max((MAX_IMAGE_COUNT + MAX_VIDEO_COUNT), 1),
            1
        ) * SCALE;

        // Weighted sum
        uint128 score = (WEIGHT_CONSENSUS *
            Tc +
            WEIGHT_CONSENSUS_STRENGTH *
            Tcs +
            WEIGHT_SPATIAL *
            Tsp +
            WEIGHT_EVIDENCE *
            Te) / SCALE;

        return (score >= ACCEPT_SCORE, score);
    }

    function _min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function _max(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? a : b;
    }

    function _distance(
        Location memory a,
        Location memory b
    ) internal pure returns (uint128) {
        int128 latDiff = a.latitude - b.latitude;
        int128 lngDiff = a.longitude - b.longitude;
        return uint128(latDiff * latDiff + lngDiff * lngDiff);
    }
}
