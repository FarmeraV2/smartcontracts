// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.30;

// import {TrustPackage} from "../interfaces/TrustPackage.sol";

// /**
//  * @title StepAuditorTrustPackage
//  * @notice Computes trust scores for steps using auditor verification data.
//  * @dev Replaces StepTransparencyPackage for the auditor verification context.
//  *      Weights: coverage 35%, verification_rate 35%, activity 15%, consensus_quality 15%
//  *      Rejected logs receive 4x penalty amplification.
//  */
// contract StepAuditorTrustPackage is TrustPackage {
//     uint128 constant SCALE = 100;

//     uint128 constant WEIGHT_COVERAGE = 35;
//     uint128 constant WEIGHT_VERIFICATION_RATE = 35;
//     uint128 constant WEIGHT_ACTIVITY = 15;
//     uint128 constant WEIGHT_CONSENSUS_QUALITY = 15;

//     uint128 constant REJECTION_PENALTY_MULTIPLIER = 4;

//     struct StepAuditorData {
//         uint128 totalLogs;          // total active logs in step
//         uint128 verifiedLogs;       // logs that passed auditor verification
//         uint128 rejectedLogs;       // logs that failed auditor verification
//         uint128 unverifiedLogs;     // logs not sent to auditors (skipped)
//         uint128 activeDays;         // distinct days with log activity
//         uint128 totalDays;          // total span of step in days
//         uint128 minLogs;            // minimum required logs for step
//         uint128 avgConsensusWeight; // average consensus weight (0-100)
//     }

//     function computeTrustScore(bytes calldata payload) external pure returns (uint128) {
//         StepAuditorData memory data = abi.decode(payload, (StepAuditorData));

//         // Coverage: how many logs vs minimum required
//         uint128 Tcov = _min((data.totalLogs * SCALE) / _max(data.minLogs, 1), SCALE);

//         // Verification rate: verified / (verified + rejected + unverified)
//         // Rejected logs count as 4x negative
//         uint128 totalEffective = data.verifiedLogs + (data.rejectedLogs * REJECTION_PENALTY_MULTIPLIER) + data.unverifiedLogs;
//         uint128 Tvr = 0;
//         if (totalEffective > 0) {
//             Tvr = (data.verifiedLogs * SCALE) / totalEffective;
//         } else if (data.totalLogs > 0) {
//             Tvr = 70; // default discount for unverified
//         }

//         // Activity regularity: active days relative to total days
//         uint128 Tact = 0;
//         if (data.totalDays > 0) {
//             Tact = _min((data.activeDays * SCALE) / data.totalDays, SCALE);
//         }

//         // Consensus quality: average consensus weight from auditor votes
//         uint128 Tcq = _min(data.avgConsensusWeight, SCALE);

//         // Weighted sum
//         uint128 score = (
//             WEIGHT_COVERAGE * Tcov +
//             WEIGHT_VERIFICATION_RATE * Tvr +
//             WEIGHT_ACTIVITY * Tact +
//             WEIGHT_CONSENSUS_QUALITY * Tcq
//         ) / SCALE;

//         return score;
//     }

//     function _min(uint128 a, uint128 b) internal pure returns (uint128) {
//         return a < b ? a : b;
//     }

//     function _max(uint128 a, uint128 b) internal pure returns (uint128) {
//         return a > b ? a : b;
//     }
// }
