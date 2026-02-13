// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.30;

// import {Test} from "forge-std/Test.sol";
// import {LogDefaultTrustPackage} from "../../src/trustworthiness/packages/LogDefaultTrustPackage.sol";

// contract LogDefaultTrustPackageTest is Test {
//     LogDefaultTrustPackage pkg;

//     struct Location {
//         int128 latitude;
//         int128 longitude;
//     }

//     struct LogData {
//         bool verified;
//         bool imageVerified;
//         uint128 imageCount;
//         uint128 videoCount;
//         Location logLocation;
//         Location plotLocation;
//     }

//     function setUp() external {
//         pkg = new LogDefaultTrustPackage();
//     }

//     function test_perfectScore() external view {
//         LogData memory data = LogData({
//             verified: true,
//             imageVerified: true,
//             imageCount: 1,
//             videoCount: 1,
//             logLocation: Location({latitude: 10_000_000, longitude: 20_000_000}),
//             plotLocation: Location({latitude: 10_000_000, longitude: 20_000_000})
//         });
//         uint128 score = pkg.computeTrustScore(abi.encode(data));
//         assertEq(score, 100);
//     }

//     function test_zeroScore() external view {
//         LogData memory data = LogData({
//             verified: false,
//             imageVerified: false,
//             imageCount: 0,
//             videoCount: 0,
//             logLocation: Location({latitude: 0, longitude: 0}),
//             plotLocation: Location({latitude: 1_000_000, longitude: 1_000_000})
//         });
//         uint128 score = pkg.computeTrustScore(abi.encode(data));
//         assertEq(score, 0);
//     }

//     function test_verifiedOnlyScore() external view {
//         LogData memory data = LogData({
//             verified: true,
//             imageVerified: false,
//             imageCount: 0,
//             videoCount: 0,
//             logLocation: Location({latitude: 0, longitude: 0}),
//             plotLocation: Location({latitude: 1_000_000, longitude: 1_000_000})
//         });
//         uint128 score = pkg.computeTrustScore(abi.encode(data));
//         // Only provenance contributes: weight=20
//         assertEq(score, 20);
//     }

//     function test_nearbyLocationBoostsSpatialScore() external view {
//         LogData memory data = LogData({
//             verified: false,
//             imageVerified: false,
//             imageCount: 0,
//             videoCount: 0,
//             logLocation: Location({latitude: 10_000_000, longitude: 20_000_000}),
//             plotLocation: Location({latitude: 10_000_000, longitude: 20_000_000})
//         });
//         uint128 score = pkg.computeTrustScore(abi.encode(data));
//         assertGt(score, 0);
//     }

//     function test_evidenceOnlyScore() external view {
//         LogData memory data = LogData({
//             verified: false,
//             imageVerified: false,
//             imageCount: 1,
//             videoCount: 0,
//             logLocation: Location(0, 0),
//             plotLocation: Location({latitude: 1_000_000, longitude: 1_000_000})
//         });
//         uint128 score = pkg.computeTrustScore(abi.encode(data));
//         // (1*1 + 1*0) / (1+1) = 0 due to integer division, so Tec = 0
//         assertEq(score, 0);
//     }
// }
