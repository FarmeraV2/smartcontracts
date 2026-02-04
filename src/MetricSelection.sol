// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

contract MetricSelection {
    error MetricSelection__TrustPackageExisted();
    error MetricSelection__InvalidAddress();
    error MetricSelection__InvalidDataType();

    mapping(bytes32 => address) private s_trustPackages;

    event TrustPackageRegistered(bytes32 indexed key);

    function registerTrustPackage(string memory dataType, string memory context, address addr) external {
        bytes32 key = keccak256(abi.encodePacked(dataType, context));

        if (bytes(dataType).length == 0 || bytes(context).length == 0) {
            revert MetricSelection__InvalidDataType();
        }

        if (addr == address(0)) {
            revert MetricSelection__InvalidAddress();
        }

        if (s_trustPackages[key] != address(0)) {
            revert MetricSelection__TrustPackageExisted();
        }

        s_trustPackages[key] = addr;

        emit TrustPackageRegistered(key);
    }

    function getTrustPackage(string memory dataType, string memory context) external view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(dataType, context));
        return s_trustPackages[key];
    }
}
