// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.30;

// import {TrustPackage} from "../interfaces/TrustPackage.sol";

// /**
//  * @title StepTrustPackage
//  * @notice Computes the Step Trust Index from raw database values.
//  *
//  * @dev DC, VR, TR, and GP are computed on-chain from raw counts and timestamps.
//  *      CR is the only oracle input — it requires keyword matching against natural
//  *      language log descriptions, which cannot be executed on-chain.
//  *
//  *      AHP pairwise matrix (4×4), CR ≈ 0.04 < 0.10 (Saaty 1980 threshold):
//  *         DC   VR   TR   CR
//  *      DC [1    2    5    4 ]   w ≈ 0.47
//  *      VR [1/2  1    4    3 ]   w ≈ 0.30
//  *      TR [1/5  1/4  1    1/2]  w ≈ 0.10
//  *      CR [1/4  1/3  2    1 ]   w ≈ 0.13
//  *
//  *      Formula:
//  *          I_step = (47·DC + 30·VR + 13·CR + 10·TR) / 100 × GP / 100
//  */
// contract StepTrustPackage is TrustPackage {
//     uint128 constant SCALE = 100;

//     uint128 constant WEIGHT_DC = 47;
//     uint128 constant WEIGHT_VR = 30;
//     uint128 constant WEIGHT_CR = 13;
//     uint128 constant WEIGHT_TR = 10;

//     uint128 constant ACCEPT_SCORE = 60;
//     uint128 constant DEFAULT_UNVERIFIED_DISCOUNT = 70;
//     uint256 constant CV_SCALE_FACTOR = 50;
//     uint256 constant GAP_THRESHOLD = 3;

//     struct StepData {
//         uint128 totalLogs;
//         uint128 verifiedLogs;
//         uint128 rejectedLogs;
//         uint128 pendingLogs;
//         uint128 minLogs;
//         uint128 cr;
//         uint64[] timestamps;
//     }

//     function computeTrustScore(
//         bytes calldata payload
//     ) external pure returns (bool, uint128) {
//         StepData memory data = abi.decode(payload, (StepData));

//         uint128 dc = _computeDC(data);
//         uint128 vr = _computeVR(data);
//         uint128 tr = _computeTR(data.timestamps);
//         uint128 gp = _computeGP(data.timestamps);
//         uint128 cr = data.cr > SCALE ? SCALE : data.cr;

//         uint128 raw = (WEIGHT_DC *
//             dc +
//             WEIGHT_VR *
//             vr +
//             WEIGHT_CR *
//             cr +
//             WEIGHT_TR *
//             tr) / SCALE;

//         uint128 score = (raw * gp) / SCALE;

//         return (score >= ACCEPT_SCORE, score);
//     }

//     function _computeDC(StepData memory data) internal pure returns (uint128) {
//         if (data.totalLogs == 0) return 0;

//         uint128 avgLogScore = uint128(
//             (uint256(data.verifiedLogs) *
//                 100 +
//                 uint256(data.pendingLogs) *
//                 DEFAULT_UNVERIFIED_DISCOUNT) / data.totalLogs
//         );

//         uint128 coverage = data.minLogs == 0
//             ? SCALE
//             : _min128((data.totalLogs * SCALE) / data.minLogs, SCALE);

//         return (coverage * avgLogScore) / SCALE;
//     }

//     function _computeVR(StepData memory data) internal pure returns (uint128) {
//         uint128 reviewed = data.verifiedLogs + data.rejectedLogs;
//         if (reviewed == 0) return DEFAULT_UNVERIFIED_DISCOUNT;
//         return uint128((uint256(data.verifiedLogs) * SCALE) / reviewed);
//     }

//     function _computeTR(
//         uint64[] memory timestamps
//     ) internal pure returns (uint128) {
//         uint256 n = timestamps.length;
//         if (n <= 1) return 50; // insufficient data → neutral

//         uint64[] memory sorted = _insertionSort(timestamps);

//         // Gaps between consecutive timestamps (seconds)
//         uint256[] memory gaps = new uint256[](n - 1);
//         uint256 gapSum = 0;
//         for (uint256 i = 1; i < n; i++) {
//             gaps[i - 1] = uint256(sorted[i]) - uint256(sorted[i - 1]);
//             gapSum += gaps[i - 1];
//         }
//         uint256 gapCount = n - 1;
//         uint256 mean = gapSum / gapCount;
//         if (mean == 0) return 100; // all logs at same instant → perfectly regular

//         // Variance of gaps
//         uint256 varianceSum = 0;
//         for (uint256 i = 0; i < gapCount; i++) {
//             uint256 diff = gaps[i] > mean ? gaps[i] - mean : mean - gaps[i];
//             varianceSum += diff * diff;
//         }
//         uint256 variance = varianceSum / gapCount;

//         // TR × 100 = 100 − min(sqrt(variance) × 50 / mean, 100)
//         uint256 sqrtVar = _sqrt(variance);
//         uint256 cvTerm = (sqrtVar * 50) / mean;

//         if (cvTerm >= 100) return 0;
//         return uint128(100 - cvTerm);
//     }

//     function _computeGP(
//         uint64[] memory timestamps
//     ) internal pure returns (uint128) {
//         uint256 n = timestamps.length;
//         if (n <= 1) return 100;

//         uint64[] memory sorted = _insertionSort(timestamps);

//         uint256 totalSpan = uint256(sorted[n - 1]) - uint256(sorted[0]);
//         if (totalSpan == 0) return 100;

//         uint256 expectedInterval = totalSpan / n;
//         if (expectedInterval == 0) return 100;

//         uint256 suspicious = 0;
//         for (uint256 i = 1; i < n; i++) {
//             if (
//                 uint256(sorted[i]) - uint256(sorted[i - 1]) >
//                 expectedInterval * GAP_THRESHOLD
//             ) {
//                 suspicious++;
//             }
//         }

//         if (suspicious == 0) return 100;
//         if (suspicious == 1) return 74;
//         if (suspicious == 2) return 55;
//         if (suspicious == 3) return 41;
//         if (suspicious == 4) return 30;
//         if (suspicious == 5) return 22;
//         return 17; // floor: exp(−0.3 × 6) ≈ 0.165
//     }

//     function _insertionSort(
//         uint64[] memory arr
//     ) internal pure returns (uint64[] memory) {
//         uint256 n = arr.length;
//         uint64[] memory out = new uint64[](n);
//         for (uint256 i = 0; i < n; i++) out[i] = arr[i];
//         for (uint256 i = 1; i < n; i++) {
//             uint64 key = out[i];
//             uint256 j = i;
//             while (j > 0 && out[j - 1] > key) {
//                 out[j] = out[j - 1];
//                 j--;
//             }
//             out[j] = key;
//         }
//         return out;
//     }

//     // Babylonian (Newton's method) integer square root
//     function _sqrt(uint256 x) internal pure returns (uint256) {
//         if (x == 0) return 0;
//         uint256 z = (x + 1) / 2;
//         uint256 y = x;
//         while (z < y) {
//             y = z;
//             z = (x / z + z) / 2;
//         }
//         return y;
//     }

//     function _min128(uint128 a, uint128 b) internal pure returns (uint128) {
//         return a < b ? a : b;
//     }
// }
