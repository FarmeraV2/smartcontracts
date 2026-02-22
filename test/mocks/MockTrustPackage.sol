// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../../src/trustworthiness/interfaces/TrustPackage.sol";

contract MockTrustPackage is TrustPackage {
    uint128 private s_score;
    bool private s_accept;

    constructor(uint128 score, bool accept) {
        s_score = score;
        s_accept = accept;
    }

    function computeTrustScore(bytes calldata) external view override returns (bool, uint128) {
        return (s_accept, s_score);
    }
}
