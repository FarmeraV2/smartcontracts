// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../../src/trustworthiness/interfaces/TrustPackage.sol";

contract MockTrustPackage is TrustPackage {
    uint128 private s_score;

    constructor(uint128 score) {
        s_score = score;
    }

    function computeTrustScore(bytes calldata) external view override returns (uint128) {
        return s_score;
    }
}
