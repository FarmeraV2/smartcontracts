// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../interfaces/TrustPackage.sol";
import {AuditorRegistry} from "../../auditor/AuditorRegistry.sol";

contract LogAuditorPackage is TrustPackage {
    uint128 constant SCALE = 100;
    uint128 constant MAX_DISTANCE = 100_000; // ~100 meters in 1e6 scaled lat/lng
    uint128 constant MAX_IMAGE_COUNT = 1;
    uint128 constant MAX_VIDEO_COUNT = 1;

    uint128 constant WEIGHT_CONSENSUS = 55;
    uint128 constant WEIGHT_SPATIAL = 30;
    uint128 constant WEIGHT_EVIDENCE = 15;
    uint128 constant ACCEPT_SCORE = 70;

    struct Location {
        int128 latitude; // lat * 1e6
        int128 longitude; // lng * 1e6
    }

    struct LogAuditorData {
        bytes32 identifier;
        uint64 id;
        uint128 imageCount;
        uint128 videoCount;
        Location logLocation;
        Location plotLocation;
    }

    AuditorRegistry private s_auditorRegistry;

    constructor(address auditorRegistry) {
        s_auditorRegistry = AuditorRegistry(auditorRegistry);
    }

    function computeTrustScore(bytes calldata payload) external view returns (bool, uint128) {
        LogAuditorData memory data = abi.decode(payload, (LogAuditorData));

        // Tc — Reputation-weighted vote ratio [0, 100]
        // Models the posterior mean of Beta(α, β) where:
        //   α = Σ reputationScore_i  for votes isValid = true
        //   β = Σ reputationScore_i  for votes isValid = false
        // Tc = α / (α + β) × 100
        // Jøsang & Ismail (2002): Beta Reputation System.
        AuditorRegistry.Verification[] memory verifications =
            s_auditorRegistry.getVerifications(data.identifier, data.id);

        uint256 alpha = 0;
        uint256 beta_ = 0;
        for (uint256 i = 0; i < verifications.length; i++) {
            uint256 rep = s_auditorRegistry.getAuditor(verifications[i].auditor).reputationScore;
            if (verifications[i].isValid) {
                alpha += rep;
            } else {
                beta_ += rep;
            }
        }
        uint128 Tc = (alpha + beta_) > 0 ? uint128((alpha * SCALE) / (alpha + beta_)) : 0;

        // Tsp — Spatial Plausibility [0 or 100]
        uint128 Tsp = 0;
        uint128 dist = _distance(data.plotLocation, data.logLocation);
        if (dist <= MAX_DISTANCE * MAX_DISTANCE) {
            Tsp = SCALE;
        }

        // Te — Evidence Completeness [0, 50, or 100]
        // Te = min((imageCount + videoCount) / (MAX_IMAGE + MAX_VIDEO), 1) × 100
        // Wang & Strong (1996): Completeness (Contextual DQ).
        // Pipino et al. (2002): capped ratio metric.
        uint128 Te = _min(
            ((MAX_IMAGE_COUNT * data.imageCount + MAX_VIDEO_COUNT * data.videoCount) * SCALE)
                / _max(MAX_IMAGE_COUNT + MAX_VIDEO_COUNT, 1),
            SCALE
        );

        uint128 score = (WEIGHT_CONSENSUS * Tc + WEIGHT_SPATIAL * Tsp + WEIGHT_EVIDENCE * Te) / SCALE;

        return (score >= ACCEPT_SCORE, score);
    }

    function _min(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function _max(uint128 a, uint128 b) internal pure returns (uint128) {
        return a > b ? a : b;
    }

    function _distance(Location memory a, Location memory b) internal pure returns (uint128) {
        int128 latDiff = a.latitude - b.latitude;
        int128 lngDiff = a.longitude - b.longitude;
        return uint128(latDiff * latDiff + lngDiff * lngDiff);
    }
}
