// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceFeedConsumer} from "./PriceFeedConsumer.sol";

contract AuditorRegistry {
    using PriceFeedConsumer for uint256;

    error AuditorRegistry__InvalidAmount(address);
    error AuditorRegistry__InvalidAuditor(address);
    error AuditorRegistry__AlreadyRegistered(address);
    error AuditorRegistry__AlreadyVerified(address);

    event AuditorRegistered(
        address indexed auditor,
        string name,
        uint256 stakedTokens
    );
    event VerificationSubmitted(
        bytes32 indexed identifier,
        uint64 indexed id,
        address indexed auditor,
        bool isValid
    );
    event VerificationFinalized(
        bytes32 indexed identifier,
        uint64 indexed id,
        bool consensus
    );
    event AuditorSlashed(address indexed auditor, uint256 amount);

    uint256 private constant MIN_STAKE = 1 * 1e18; // 1$
    uint256 private constant INITIAL_REPUTATION = 50;
    uint256 private constant MIN_AUDITORS = 2;
    uint256 private constant REPUTATION_PENALTY = 5;
    uint256 private constant REPUTATION = 2;
    uint256 private constant SLASH_AMOUNT = 0.1 ether;

    AggregatorV3Interface private priceFeed;

    struct Auditor {
        bool isActive;
        address auditorAddress;
        uint256 reputationScore;
        uint256 stakedTokens;
        string name;
    }

    struct Verification {
        bool isValid;
        address auditor;
        uint256 timestamp;
    }

    mapping(address => Auditor) public auditors;
    mapping(bytes32 => mapping(uint64 => Verification[])) public verifications;

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function registerAuditor(string memory name) external payable {
        if (msg.value.convert(priceFeed) < MIN_STAKE) {
            revert AuditorRegistry__InvalidAmount(msg.sender);
        }

        if (auditors[msg.sender].isActive) {
            revert AuditorRegistry__AlreadyRegistered(msg.sender);
        }

        auditors[msg.sender] = Auditor({
            auditorAddress: msg.sender,
            name: name,
            reputationScore: INITIAL_REPUTATION,
            stakedTokens: msg.value,
            isActive: true
        });

        emit AuditorRegistered(msg.sender, name, msg.value);
    }

    function verify(bytes32 identifier, uint64 id, bool isValid) external {
        if (!auditors[msg.sender].isActive) {
            revert AuditorRegistry__InvalidAuditor(msg.sender);
        }

        Verification[] storage v = verifications[identifier][id];

        uint256 i = 0;
        for (i; i < v.length; i++) {
            if (v[i].auditor == msg.sender) {
                revert AuditorRegistry__AlreadyVerified(msg.sender);
            }
        }

        v.push(
            Verification({
                auditor: msg.sender,
                isValid: isValid,
                timestamp: block.timestamp
            })
        );

        emit VerificationSubmitted(identifier, id, msg.sender, isValid);

        if (v.length >= MIN_AUDITORS) {
            bool consensus = calculateConsensus(identifier, id);
            finalizeVerification(identifier, id, consensus);
        }
    }

    function calculateConsensus(
        bytes32 identifier,
        uint64 id
    ) internal view returns (bool) {
        uint256 validVotes = 0;
        uint256 invalidVotes = 0;

        Verification[] storage v = verifications[identifier][id];

        uint256 i = 0;

        for (i; i < v.length; i++) {
            uint256 weight = auditors[v[i].auditor].reputationScore;
            if (v[i].isValid) {
                validVotes += weight;
            } else {
                invalidVotes += weight;
            }
        }

        return validVotes > invalidVotes;
    }

    function finalizeVerification(
        bytes32 identifier,
        uint64 id,
        bool consensus
    ) internal {
        Verification[] storage v = verifications[identifier][id];

        uint256 i = 0;

        for (i; i < v.length; i++) {
            if (v[i].isValid == consensus) {
                auditors[v[i].auditor].reputationScore += REPUTATION;
            } else {
                slashAuditor(v[i].auditor, SLASH_AMOUNT);
            }
        }

        emit VerificationFinalized(identifier, id, consensus);
    }

    function slashAuditor(address auditor, uint256 amount) internal {
        auditors[auditor].stakedTokens -= amount;
        auditors[auditor].reputationScore -= REPUTATION_PENALTY;

        if (auditors[auditor].stakedTokens.convert(priceFeed) < MIN_STAKE) {
            auditors[auditor].isActive = false;
        }

        emit AuditorSlashed(auditor, amount);
    }

    function getAuditor(
        address auditor
    ) external view returns (Auditor memory) {
        return auditors[auditor];
    }

    function getVerifications(
        bytes32 identifier,
        uint64 id
    ) external view returns (Verification[] memory) {
        return verifications[identifier][id];
    }
}
