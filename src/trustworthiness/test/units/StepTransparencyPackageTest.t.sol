// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {StepTransparencyPackage} from "../../packages/StepTransparencyPackage.sol";

contract StepTransparencyPackageTest is Test {
    StepTransparencyPackage pkg;

    struct Data {
        uint128 validLogs;
        uint128 invalidLogs;
        uint128 active;
        uint128 unactive;
        uint128 minLogs;
    }

    function setUp() external {
        pkg = new StepTransparencyPackage();
    }

    function test_perfectScore() external view {
        Data memory data = Data({validLogs: 10, invalidLogs: 0, active: 10, unactive: 0, minLogs: 10});
        uint128 score = pkg.computeTrustScore(abi.encode(data));
        assertEq(score, 100);
    }

    function test_halfCoverageFullActivity() external view {
        Data memory data = Data({validLogs: 5, invalidLogs: 0, active: 10, unactive: 0, minLogs: 10});
        uint128 score = pkg.computeTrustScore(abi.encode(data));
        // Lc=50, Lar=100 => (50*60 + 100*40)/100 = 70
        assertEq(score, 70);
    }

    function test_penaltyWithInvalidLogs() external view {
        Data memory data = Data({validLogs: 10, invalidLogs: 10, active: 10, unactive: 0, minLogs: 10});
        uint128 score = pkg.computeTrustScore(abi.encode(data));
        // invalidRatio=50, penalty=100-min(150,100)=0 => score=0
        assertEq(score, 0);
    }

    function test_partialActivityRatio() external view {
        Data memory data = Data({validLogs: 10, invalidLogs: 0, active: 5, unactive: 5, minLogs: 10});
        uint128 score = pkg.computeTrustScore(abi.encode(data));
        // Lc=100, Lar=50 => (100*60 + 50*40)/100 = 80
        assertEq(score, 80);
    }

    function test_excessValidLogsCapped() external view {
        Data memory data = Data({validLogs: 20, invalidLogs: 0, active: 10, unactive: 0, minLogs: 10});
        uint128 score = pkg.computeTrustScore(abi.encode(data));
        // Lc capped at 100 => score=100
        assertEq(score, 100);
    }
}
