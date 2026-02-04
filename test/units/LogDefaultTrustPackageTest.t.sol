// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {LogDefaultTrustPackage} from "../../src/packages/LogDefaultTrustPackage.sol";

contract LogDefaultTrustPackageTest is Test {
    LogDefaultTrustPackage logDefaultTrustPackage;

    // Constants from contract
    uint256 constant MAX_DISTANCE = 100_000;
    uint256 constant MAX_IMAGE_COUNT = 1;
    uint256 constant MAX_VIDEO_COUNT = 1;
    uint256 constant SCALE = 100;
    uint256 constant WEIGHT_PROVENANCE = 50;
    uint256 constant WEIGHT_SPATIAL_PLAUSIBILITY = 30;
    uint256 constant WEIGHT_EVIDENCE_COMPLETENESS = 20;

    struct Location {
        int256 latitude;
        int256 longitude;
    }

    struct LogData {
        bool verified;
        uint256 imageCount;
        uint256 videoCount;
        Location logLocation;
        Location plotLocation;
    }

    function setUp() external {
        logDefaultTrustPackage = new LogDefaultTrustPackage();
    }

    // ============ Spatial Plausibility Tests ============

    function testComputeTrustScore_MaxScoreWhenLocationsIdentical() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        assertEq(score, 100);
    }

    function testComputeTrustScore_ReducedScoreWhenLocationDistant() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 20900000, longitude: 105100000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertLt(score, 100);
    }

    function testComputeTrustScore_ZeroScoreWhenDistanceBeyondMax() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 0, longitude: 0})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        // Distance is very large, so spatial plausibility contribution should be low
        // Score should be primarily from evidence completeness and step compliance
        uint256 expectedScore = (WEIGHT_EVIDENCE_COMPLETENESS * SCALE + WEIGHT_PROVENANCE * SCALE) / SCALE;
        assertEq(score, expectedScore);
    }

    function testComputeTrustScore_SmallDistance() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000100, longitude: 105000100})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertGt(score, 0);
    }

    // ============ Evidence Completeness Tests ============

    function testComputeTrustScore_MaxEvidenceWithAllMedia() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertEq(score, 100);
    }

    function testComputeTrustScore_NoImages() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 0,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertLt(score, 100);
    }

    function testComputeTrustScore_NoVideos() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 0,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertLt(score, 100);
    }

    function testComputeTrustScore_NoMediaAtAll() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 0,
            videoCount: 0,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        uint256 expectedScore = WEIGHT_PROVENANCE + WEIGHT_SPATIAL_PLAUSIBILITY;
        assertEq(score, expectedScore);
    }

    function testComputeTrustScore_ExcessiveImages() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 10,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        // Excessive images should be capped at 1 * SCALE
        assertEq(score, 100);
    }

    function testComputeTrustScore_ExcessiveVideos() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 10,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        // Excessive videos should be capped at 1 * SCALE
        assertEq(score, 100);
    }

    // ============ Step Compliance Tests ============

    function testComputeTrustScore_CompliantLog() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertEq(score, 100);
    }

    // ============ Combined Tests ============

    function testComputeTrustScore_AllFactorsAtMinimum() external view {
        LogData memory logData = LogData({
            verified: false,
            imageCount: 0,
            videoCount: 0,
            logLocation: Location({latitude: 0, longitude: 0}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertEq(score, 0);
    }

    function testComputeTrustScore_VerifiedCompliantButDistantLocation() external view {
        // Create a log far from the plot
        int256 farLatitude = 20000000; // Approximately 1 degree away
        int256 farLongitude = 105000000;

        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: farLatitude, longitude: farLongitude})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        uint256 expectedScore = WEIGHT_EVIDENCE_COMPLETENESS + WEIGHT_PROVENANCE;
        assertEq(score, expectedScore);
    }

    // ============ Edge Case Tests ============

    function testComputeTrustScore_NegativeCoordinates() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: -21000000, longitude: -105000000}),
            plotLocation: Location({latitude: -21000000, longitude: -105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertEq(score, 100);
    }

    function testComputeTrustScore_MixedPositiveNegativeCoordinates() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: -105000000}),
            plotLocation: Location({latitude: -21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertGt(score, 0);
    }

    function testComputeTrustScore_LargeCoordinateValues() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: type(int256).max, longitude: type(int256).max}),
            plotLocation: Location({latitude: type(int256).max - 1000, longitude: type(int256).max - 1000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        // Should not revert and return a valid score
        assertGe(score, 0);
    }

    function testComputeTrustScore_ZeroCoordinates() external view {
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 0, longitude: 0}),
            plotLocation: Location({latitude: 0, longitude: 0})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);
        assertEq(score, 100);
    }

    // ============ Score Distribution Tests ============

    function testComputeTrustScore_ScoreComponentWeights() external view {
        // Test that weights are properly applied
        LogData memory logData = LogData({
            verified: true,
            imageCount: 1,
            videoCount: 1,
            logLocation: Location({latitude: 21000000, longitude: 105000000}),
            plotLocation: Location({latitude: 21000000, longitude: 105000000})
        });

        bytes memory payload = abi.encode(logData);
        uint256 score = logDefaultTrustPackage.computeTrustScore(payload);

        // With all factors at maximum:
        // Tsp = 100 (distance = 0)
        // Tec = 100 (full evidence)
        // Tsc = 100 (compliant)
        // Score = (30*100 + 50*100 + 20*100) / 100 = 100
        assertEq(score, 100);
    }
}
