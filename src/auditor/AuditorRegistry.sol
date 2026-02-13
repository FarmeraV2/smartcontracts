// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceFeedConsumer} from "./PriceFeedConsumer.sol";
import {
    VRFConsumerBaseV2Plus
} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    VRFV2PlusClient
} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract AuditorRegistry is VRFConsumerBaseV2Plus {
    using PriceFeedConsumer for uint256;

    error AuditorRegistry__InvalidAmount(address);
    error AuditorRegistry__InvalidAuditor(address);
    error AuditorRegistry__InvalidDeadline();
    error AuditorRegistry__NotEnoughAuditor();
    error AuditorRegistry__AlreadyRegistered(address);
    error AuditorRegistry__AlreadyVerified(address);
    error AuditorRegistry__VerificationPending(bytes32, uint64);
    error AuditorRegistry__NotAssigned(address);
    error AuditorRegistry__DeadlineExpired(bytes32, uint64);
    error AuditorRegistry__VerificationNotExpired(bytes32, uint64);
    error AuditorRegistry__AlreadyFinalized(bytes32, uint64);

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

    // to get identifiers in chainlink random function callback
    struct VerificationRequest {
        bytes32 identifier;
        uint64 id;
        uint256 deadline;
    }

    uint256 private constant MIN_STAKE = 1 * 1e18; // 1$
    uint256 private constant INITIAL_REPUTATION = 50;
    uint256 private constant REPUTATION_PENALTY = 5;
    uint256 private constant REPUTATION = 2;
    uint256 private constant SLASH_AMOUNT = 0.1 ether;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    AggregatorV3Interface private priceFeed;
    uint256 private immutable SUBSCRIPTION_ID;
    bytes32 private immutable KEY_HASH;
    uint32 private immutable CALLBACK_GAS_LIMIT;
    uint256 public constant MIN_AUDITORS = 5;

    uint256 counter = 0;
    mapping(address => Auditor) private auditors;
    mapping(address => uint256) private auditorIndex;
    address[] private auditorAddresses;

    mapping(bytes32 => mapping(uint64 => Verification[])) private verifications;
    mapping(bytes32 => mapping(uint64 => bool)) public verificationResult;
    mapping(bytes32 => mapping(uint64 => mapping(address => bool)))
        private assignedAuditors;
    mapping(bytes32 => mapping(uint64 => address[])) private assignments;
    mapping(bytes32 => mapping(uint64 => uint256))
        private verificationDeadlines;

    mapping(bytes32 => mapping(uint64 => bool)) public finalized;
    mapping(uint256 => VerificationRequest) public requests;

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
        bool consensus,
        uint256 totalVote
    );
    event VerificationRequested(
        bytes32 indexed identifier,
        uint64 indexed id,
        address[] assignedAuditors,
        uint256 deadline
    );
    event AuditorSlashed(address indexed auditor, uint256 amount);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        KEY_HASH = _keyHash;
        SUBSCRIPTION_ID = _subscriptionId;
        CALLBACK_GAS_LIMIT = _callbackGasLimit;
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
        auditorAddresses.push(msg.sender);
        counter++;

        emit AuditorRegistered(msg.sender, name, msg.value);
    }

    function requestVerification(
        bytes32 identifier,
        uint64 id,
        uint256 deadline
    ) external {
        if (deadline <= block.timestamp) {
            revert AuditorRegistry__InvalidDeadline();
        }
        if (auditorAddresses.length < MIN_AUDITORS) {
            revert AuditorRegistry__NotEnoughAuditor();
        }
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,
                subId: SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: 2,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        requests[requestId] = VerificationRequest({
            identifier: identifier,
            id: id,
            deadline: deadline
        });
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        VerificationRequest memory req = requests[requestId];
        if (verificationDeadlines[req.identifier][req.id] != 0) {
            revert AuditorRegistry__VerificationPending(req.identifier, req.id);
        }

        uint256 randomSeed = randomWords[0];

        address[] memory temp = auditorAddresses;
        verificationDeadlines[req.identifier][req.id] = req.deadline;

        uint256 i = 0;
        uint256 n = auditorAddresses.length;
        for (i; i < MIN_AUDITORS; i++) {
            uint256 j = i +
                (uint256(keccak256(abi.encode(randomSeed, i))) % (n - i));

            (temp[i], temp[j]) = (temp[j], temp[i]);
        }
        address[] memory assignedAddresses = new address[](MIN_AUDITORS);
        i = 0;
        for (i; i < MIN_AUDITORS; i++) {
            address selected = temp[i];
            assignedAddresses[i] = selected;
            assignedAuditors[req.identifier][req.id][selected] = true;
            assignments[req.identifier][req.id].push(selected);
        }
        emit VerificationRequested(
            req.identifier,
            req.id,
            assignedAddresses,
            req.deadline
        );
    }

    function verify(bytes32 identifier, uint64 id, bool isValid) external {
        if (!auditors[msg.sender].isActive) {
            revert AuditorRegistry__InvalidAuditor(msg.sender);
        }

        if (!assignedAuditors[identifier][id][msg.sender]) {
            revert AuditorRegistry__NotAssigned(msg.sender);
        }

        if (finalized[identifier][id]) {
            revert AuditorRegistry__AlreadyFinalized(identifier, id);
        }

        uint256 deadline = verificationDeadlines[identifier][id];
        if (deadline > 0 && block.timestamp > deadline) {
            revert AuditorRegistry__DeadlineExpired(identifier, id);
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

    /**
     * @notice Finalize an expired verification with whatever votes exist.
     * @dev Can be called by anyone after the deadline has passed.
     */
    function finalizeExpired(bytes32 identifier, uint64 id) external {
        uint256 deadline = verificationDeadlines[identifier][id];
        if (deadline == 0 || block.timestamp <= deadline) {
            revert AuditorRegistry__VerificationNotExpired(identifier, id);
        }

        if (finalized[identifier][id]) {
            revert AuditorRegistry__AlreadyFinalized(identifier, id);
        }

        Verification[] storage v = verifications[identifier][id];

        bool consensus;
        if (v.length == 0) {
            // No votes at all — reject
            consensus = false;
        } else {
            consensus = calculateConsensus(identifier, id);
        }

        finalizeVerification(identifier, id, consensus);
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
        finalized[identifier][id] = true;
        verificationResult[identifier][id] = consensus;

        Verification[] storage v = verifications[identifier][id];

        uint256 i = 0;
        uint256 len = v.length;

        for (i; i < len; i++) {
            if (v[i].isValid == consensus) {
                auditors[v[i].auditor].reputationScore += REPUTATION;
            } else {
                slashAuditor(v[i].auditor, SLASH_AMOUNT);
            }
        }

        emit VerificationFinalized(identifier, id, consensus, len);
    }

    function slashAuditor(address auditor, uint256 amount) internal {
        auditors[auditor].stakedTokens -= amount;
        auditors[auditor].reputationScore -= REPUTATION_PENALTY;

        if (auditors[auditor].stakedTokens.convert(priceFeed) < MIN_STAKE) {
            auditors[auditor].isActive = false;
            deactivateAuditor(auditor);
        }

        emit AuditorSlashed(auditor, amount);
    }

    function getAuditor(
        address auditor
    ) external view returns (Auditor memory) {
        return auditors[auditor];
    }

    function getVerificationDeadline(
        bytes32 identifier,
        uint64 id
    ) external view returns (uint256) {
        return verificationDeadlines[identifier][id];
    }

    function getVerificationAssignments(
        bytes32 identifier,
        uint64 id
    ) external view returns (address[] memory) {
        return assignments[identifier][id];
    }

    function getVerifications(
        bytes32 identifier,
        uint64 id
    ) external view returns (Verification[] memory) {
        return verifications[identifier][id];
    }

    function getVerificationResult(
        bytes32 identifier,
        uint64 id
    ) external view returns (bool) {
        return verificationResult[identifier][id];
    }

    function deactivateAuditor(address auditor) internal {
        uint256 index = auditorIndex[auditor];
        uint256 lastIndex = auditorAddresses.length - 1;

        address lastAuditor = auditorAddresses[lastIndex];

        // swap
        auditorAddresses[index] = lastAuditor;
        auditorIndex[lastAuditor] = index;

        // remove last
        auditorAddresses.pop();

        delete auditorIndex[auditor];
    }
}
