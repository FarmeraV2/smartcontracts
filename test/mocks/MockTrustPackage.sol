// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {TrustPackage} from "../../src/interfaces/TrustPackage.sol";

contract MockTrustPackage is TrustPackage {
    uint256 private s_score;

    constructor(uint256 score) {
        s_score = score;
    }

    function computeTrustScore(bytes calldata) external view override returns (uint256) {
        return s_score;
    }
}
