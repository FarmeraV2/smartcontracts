// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {Test} from "forge-std/Test.sol";
import {ProcessTracking} from "../ProcessTracking.sol";
import {DeployProcessTracking} from "../../../script/DeployProcessTracking.s.sol";

contract ProcessTrackingTest is Test {
    ProcessTracking pt;

    function setUp() external {
        DeployProcessTracking deployer = new DeployProcessTracking();
        pt = deployer.run();
    }

    function testAddLogSuccess() public {
        uint64 seasonStepId = 1;
        uint64 logId = 1;
        string memory hashed = "hash_abc";

        vm.expectEmit(true, true, true, true);
        emit ProcessTracking.LogAdded(logId, hashed);

        pt.addLog(seasonStepId, logId, hashed);

        assertEq(pt.getLog(logId), hashed);
    }

    function testGetLogs() public {
        uint64 seasonStepId = 1;
        uint64 logId1 = 1;
        uint64 logId2 = 2;

        string memory hashed1 = "hash_abc1";
        string memory hashed2 = "hash_abc2";

        pt.addLog(seasonStepId, logId1, hashed1);
        pt.addLog(seasonStepId, logId2, hashed2);

        (uint64[] memory logIds, string[] memory data) = pt.getLogs(seasonStepId);

        uint64[] memory expectedIds = new uint64[](2);
        expectedIds[0] = 1;
        expectedIds[1] = 2;

        string[] memory expectedData = new string[](2);
        expectedData[0] = "hash_abc1";
        expectedData[1] = "hash_abc2";

        for (uint64 i = 0; i < 2; i++) {
            assertEq(logIds[i], expectedIds[i]);
        }

        for (uint256 i = 0; i < expectedData.length; i++) {
            assertEq(data[i], expectedData[i]);
        }
    }

    function testAddLogRevertIfDuplicate() public {
        uint64 seasonStepId = 1;
        uint64 logId = 1;

        pt.addLog(seasonStepId, logId, "data1");

        vm.expectRevert(abi.encodeWithSelector(ProcessTracking.ProcessTracking__InvalidLogId.selector, logId));
        pt.addLog(seasonStepId, logId, "data2");
    }

    function testAddStepSuccess() public {
        uint64 seasonId = 10;
        uint64 seasonStepId = 2;
        string memory hashData = "step_hash";

        vm.expectEmit(true, true, true, true);
        emit ProcessTracking.StepAdded(seasonId, seasonStepId, hashData);

        pt.addStep(seasonId, seasonStepId, hashData);

        assertEq(pt.getStep(seasonStepId), hashData);
    }

    function testAddStepRevertIfDuplicate() public {
        uint64 seasonId = 10;
        uint64 seasonStepId = 1;

        pt.addStep(seasonId, seasonStepId, "A");

        vm.expectRevert(abi.encodeWithSelector(ProcessTracking.ProcessTracking__InvalidStepId.selector, seasonStepId));
        pt.addStep(seasonId, seasonStepId, "B");
    }

    function testGetSteps() public {
        uint64 seasonId = 1;
        uint64 stepId1 = 1;
        uint64 stepId2 = 2;
        string memory hashed1 = "hash_abc1";
        string memory hashed2 = "hash_abc2";

        pt.addStep(seasonId, stepId1, hashed1);
        pt.addStep(seasonId, stepId2, hashed2);

        (uint64[] memory ids, string[] memory data) = pt.getSteps(seasonId);

        uint64[] memory expectedIds = new uint64[](2);
        expectedIds[0] = 1;
        expectedIds[1] = 2;

        string[] memory expectedData = new string[](2);
        expectedData[0] = "hash_abc1";
        expectedData[1] = "hash_abc2";

        for (uint64 i = 0; i < 2; i++) {
            assertEq(ids[i], expectedIds[i]);
        }

        for (uint256 i = 0; i < expectedData.length; i++) {
            assertEq(data[i], expectedData[i]);
        }
    }
}
