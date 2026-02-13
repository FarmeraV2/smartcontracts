// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.30;

// import {TrustPackage} from "../interfaces/TrustPackage.sol";

// contract StepTransparencyPackage is TrustPackage {
//     uint128 constant SCALE = 100;
//     uint128 constant WEIGHT_LOG_COVERAGE = 60;
//     uint128 constant WEIGHT_ACTIVITY_RATIO = 40;

//     struct Data {
//         uint128 validLogs;
//         uint128 invalidLogs;
//         uint128 active;
//         uint128 unactive;
//         uint128 minLogs;
//     }

//     function computeTrustScore(bytes calldata payload) external pure returns (uint128) {
//         Data memory data = abi.decode(payload, (Data));

//         // Log Coverage
//         uint128 Lc = _min((data.validLogs * SCALE) / data.minLogs, SCALE);

//         // Activity Ratio
//         uint128 Lar = (data.active * SCALE) / (data.active + data.unactive);

//         uint128 penaltyFactor;
//         if (data.invalidLogs == 0) {
//             penaltyFactor = SCALE;
//         } else {
//             uint128 invalidRatio = (data.invalidLogs * SCALE) / (data.validLogs + data.invalidLogs);
//             penaltyFactor = SCALE - _min(invalidRatio * 3, SCALE);
//         }

//         uint128 score = (Lc * WEIGHT_LOG_COVERAGE + Lar * WEIGHT_ACTIVITY_RATIO) / 100;

//         score = (score * penaltyFactor) / SCALE;

//         return score;
//     }

//     function _min(uint128 a, uint128 b) internal pure returns (uint128) {
//         return a < b ? a : b;
//     }
// }
