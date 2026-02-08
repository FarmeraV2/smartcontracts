// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface TrustPackage {
    function computeTrustScore(
        bytes calldata payload
    ) external view returns (uint128);
}
