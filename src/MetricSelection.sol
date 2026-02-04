// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract MetricSelection {
    mapping(bytes32 => address) private s_trustPackages;

    event TrustPackageRegistered(bytes32 key);

    function registerTrustPackage(
        string memory dataType,
        string memory context,
        address addr
    ) external {
        bytes32 key = keccak256(abi.encodePacked(dataType, context));
        s_trustPackages[key] = addr;

        emit TrustPackageRegistered(key);
    }

    function getTrustPackage(
        string memory dataType,
        string memory context
    ) external view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(dataType, context));
        return s_trustPackages[key];
    }
}
