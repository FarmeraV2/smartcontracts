// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

contract ProcessTracking {
    error ProcessTracking__InvalidLogId(uint64);
    error ProcessTracking__InvalidStepId(uint64);

    mapping(uint64 logId => string hashedData) private s_logs;
    mapping(uint64 seasonStepId => uint64[] logIds) private s_seasonStepLogs;
    mapping(uint64 seasonStepId => string hashedData) private s_seasonStep;
    mapping(uint64 seasonId => uint64[] seasonStepIds) private s_season;

    event LogAdded(uint64 logId, string hashedData);
    event StepAdded(uint64 seasonId, uint64 seasonStepId, string hashedData);

    function addLog(uint64 seasonStepId, uint64 logId, string memory hashedData) public {
        if (bytes(s_logs[logId]).length != 0) {
            revert ProcessTracking__InvalidLogId(logId);
        }

        s_logs[logId] = hashedData;
        s_seasonStepLogs[seasonStepId].push(logId);

        emit LogAdded(logId, hashedData);
    }

    function addStep(uint64 seasonId, uint64 seasonStepId, string memory hashedData) public {
        if (bytes(s_seasonStep[seasonStepId]).length != 0) {
            revert ProcessTracking__InvalidStepId(seasonStepId);
        }

        s_seasonStep[seasonStepId] = hashedData;
        s_season[seasonId].push(seasonStepId);

        emit StepAdded(seasonId, seasonStepId, hashedData);
    }

    function getLog(uint64 logId) public view returns (string memory) {
        return s_logs[logId];
    }

    function getLogs(uint64 seasonStepId) public view returns (uint64[] memory, string[] memory) {
        uint64[] memory logIds = s_seasonStepLogs[seasonStepId];
        string[] memory data = new string[](logIds.length);
        uint32 i = 0;
        for (; i < logIds.length; i++) {
            data[i] = s_logs[logIds[i]];
        }
        return (logIds, data);
    }

    function getStep(uint64 seasonStepId) public view returns (string memory) {
        return s_seasonStep[seasonStepId];
    }

    function getSteps(uint64 seasonId) public view returns (uint64[] memory, string[] memory) {
        uint64[] memory stepIds = s_season[seasonId];
        string[] memory data = new string[](stepIds.length);
        uint32 i = 0;
        for (i; i < stepIds.length; i++) {
            data[i] = s_seasonStep[stepIds[i]];
        }
        return (stepIds, data);
    }
}
