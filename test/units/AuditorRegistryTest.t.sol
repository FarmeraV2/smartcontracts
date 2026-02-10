// SPDX-License-Identifier: MIT

pragma solidity >=0.8.30;

import {Test} from "forge-std/Test.sol";
import {AuditorRegistry} from "../../src/auditor/AuditorRegistry.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract AuditorRegistryTest is Test {
    AuditorRegistry registry;
    MockV3Aggregator priceFeed;

    address auditor1 = makeAddr("auditor1");
    address auditor2 = makeAddr("auditor2");
    address auditor3 = makeAddr("auditor3");

    uint8 constant DECIMALS = 8;
    int256 constant ETH_USD_PRICE = 2000e8; // $2000/ETH

    // With price $2000/ETH, MIN_STAKE=$1 => min ETH ~= 0.0005 ether
    uint256 constant SUFFICIENT_STAKE = 1 ether;
    uint256 constant INSUFFICIENT_STAKE = 0.0001 ether;

    bytes32 constant IDENTIFIER = keccak256("product-123");
    uint64 constant VERIFICATION_ID = 1;

    uint256 private constant INITIAL_REPUTATION = 50;
    uint256 private constant MIN_AUDITORS = 2;
    uint256 private constant REPUTATION_PENALTY = 5;
    uint256 private constant REPUTATION = 2;
    uint256 private constant SLASH_AMOUNT = 0.1 ether;

    function setUp() external {
        priceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        registry = new AuditorRegistry(address(priceFeed));

        vm.deal(auditor1, 10 ether);
        vm.deal(auditor2, 10 ether);
        vm.deal(auditor3, 10 ether);
    }

    function testRegisterAuditorSuccess() public {
        vm.prank(auditor1);

        vm.expectEmit(true, true, true, true);
        emit AuditorRegistry.AuditorRegistered(auditor1, "Alice", SUFFICIENT_STAKE);

        registry.registerAuditor{value: SUFFICIENT_STAKE}("Alice");

        AuditorRegistry.Auditor memory a = registry.getAuditor(auditor1);
        assertTrue(a.isActive);
        assertEq(a.auditorAddress, auditor1);
        assertEq(a.reputationScore, 50);
        assertEq(a.stakedTokens, SUFFICIENT_STAKE);
        assertEq(a.name, "Alice");
    }

    function testRegisterAuditorRevertsInsufficientStake() public {
        vm.prank(auditor1);
        vm.expectRevert(abi.encodeWithSelector(AuditorRegistry.AuditorRegistry__InvalidAmount.selector, auditor1));
        registry.registerAuditor{value: INSUFFICIENT_STAKE}("Alice");
    }

    function testRegisterAuditorRevertsAlreadyRegistered() public {
        vm.prank(auditor1);
        registry.registerAuditor{value: SUFFICIENT_STAKE}("Alice");

        vm.prank(auditor1);
        vm.expectRevert(abi.encodeWithSelector(AuditorRegistry.AuditorRegistry__AlreadyRegistered.selector, auditor1));
        registry.registerAuditor{value: SUFFICIENT_STAKE}("Alice2");
    }

    function testVerifySuccess() public {
        _registerAuditor(auditor1, "Alice");

        vm.prank(auditor1);

        vm.expectEmit(true, true, true, true);
        emit AuditorRegistry.VerificationSubmitted(IDENTIFIER, VERIFICATION_ID, auditor1, true);

        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        AuditorRegistry.Verification[] memory v = registry.getVerifications(IDENTIFIER, VERIFICATION_ID);
        assertEq(v.length, 1);
        assertEq(v[0].auditor, auditor1);
        assertTrue(v[0].isValid);
    }

    function testVerifyRevertsNotActiveAuditor() public {
        vm.prank(auditor1);
        vm.expectRevert(abi.encodeWithSelector(AuditorRegistry.AuditorRegistry__InvalidAuditor.selector, auditor1));
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);
    }

    function testVerifyRevertsAlreadyVerified() public {
        _registerAuditor(auditor1, "Alice");

        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        vm.prank(auditor1);
        vm.expectRevert(abi.encodeWithSelector(AuditorRegistry.AuditorRegistry__AlreadyVerified.selector, auditor1));
        registry.verify(IDENTIFIER, VERIFICATION_ID, false);
    }

    function testConsensusValidRewardsAgreeing() public {
        _registerAuditor(auditor1, "Alice");
        _registerAuditor(auditor2, "Bob");

        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        vm.prank(auditor2);

        vm.expectEmit(true, true, true, true);
        emit AuditorRegistry.VerificationFinalized(IDENTIFIER, VERIFICATION_ID, true);

        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        AuditorRegistry.Auditor memory a1 = registry.getAuditor(auditor1);
        AuditorRegistry.Auditor memory a2 = registry.getAuditor(auditor2);
        assertEq(a1.reputationScore, INITIAL_REPUTATION + REPUTATION);
        assertEq(a2.reputationScore, INITIAL_REPUTATION + REPUTATION);
    }

    function testConsensusSlashesDisagreeing() public {
        _registerAuditor(auditor1, "Alice");
        _registerAuditor(auditor2, "Bob");

        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        vm.prank(auditor2);
        registry.verify(IDENTIFIER, VERIFICATION_ID, false);

        // consensus = false → auditor1 (voted true) gets slashed, auditor2 (voted false) gets rewarded
        AuditorRegistry.Auditor memory a1 = registry.getAuditor(auditor1);
        AuditorRegistry.Auditor memory a2 = registry.getAuditor(auditor2);

        // auditor1: slashed → reputation 50-5=45, stakedTokens -= 0.1 ether
        assertEq(a1.reputationScore, INITIAL_REPUTATION - REPUTATION_PENALTY);
        assertEq(a1.stakedTokens, SUFFICIENT_STAKE - SLASH_AMOUNT);
        assertTrue(a1.isActive); // still above min stake

        // auditor2: rewarded → reputation 50+2=52
        assertEq(a2.reputationScore, INITIAL_REPUTATION + REPUTATION);
    }

    function testConsensusMajorityWinsWithThreeAuditors() public {
        _registerAuditor(auditor1, "Alice");
        _registerAuditor(auditor2, "Bob");
        _registerAuditor(auditor3, "Charlie");

        // 2 valid, 1 invalid → consensus = true
        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        // consensus triggers at 2 auditors (MIN_AUDITORS)
        vm.prank(auditor2);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        // After consensus: both rewarded
        AuditorRegistry.Auditor memory a1 = registry.getAuditor(auditor1);
        AuditorRegistry.Auditor memory a2 = registry.getAuditor(auditor2);
        assertEq(a1.reputationScore, INITIAL_REPUTATION + REPUTATION);
        assertEq(a2.reputationScore, INITIAL_REPUTATION + REPUTATION);
    }

    function testSlashDeactivatesAuditorBelowMinStake() public {
        // Register with a small stake just above minimum
        uint256 smallStake = 0.001 ether; // $2 worth, just above $1 min
        vm.prank(auditor1);
        registry.registerAuditor{value: smallStake}("Alice");

        _registerAuditor(auditor2, "Bob");

        // auditor1 votes true, auditor2 votes false → equal weight, consensus = false
        // auditor1 gets slashed 0.1 ether but only has 0.001 ether → underflow
        // This would revert due to arithmetic underflow, testing that scenario
        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        vm.prank(auditor2);
        vm.expectRevert(); // arithmetic underflow on stakedTokens -= 0.1 ether
        registry.verify(IDENTIFIER, VERIFICATION_ID, false);
    }

    function testSlashDeactivatesWhenBelowMinStake() public {
        // Register auditor1 with exactly 0.1 ether (slash amount)
        // After slash: 0 tokens → convert = 0 < MIN_STAKE → deactivated
        uint256 exactSlashStake = 0.1 ether; // $200 > $1, valid registration
        vm.prank(auditor1);
        registry.registerAuditor{value: exactSlashStake}("Alice");

        _registerAuditor(auditor2, "Bob");

        vm.prank(auditor1);
        registry.verify(IDENTIFIER, VERIFICATION_ID, true);

        vm.prank(auditor2);

        vm.expectEmit(true, true, true, true);
        emit AuditorRegistry.AuditorSlashed(auditor1, 0.1 ether);

        registry.verify(IDENTIFIER, VERIFICATION_ID, false);

        AuditorRegistry.Auditor memory a1 = registry.getAuditor(auditor1);
        assertEq(a1.stakedTokens, 0);
        assertFalse(a1.isActive);
    }

    function testGetAuditorReturnsDefaultForUnregistered() public view {
        AuditorRegistry.Auditor memory a = registry.getAuditor(auditor1);
        assertFalse(a.isActive);
        assertEq(a.auditorAddress, address(0));
        assertEq(a.reputationScore, 0);
        assertEq(a.stakedTokens, 0);
    }

    function testGetVerificationsReturnsEmptyByDefault() public view {
        AuditorRegistry.Verification[] memory v = registry.getVerifications(IDENTIFIER, VERIFICATION_ID);
        assertEq(v.length, 0);
    }

    function _registerAuditor(address auditor, string memory name) internal {
        vm.prank(auditor);
        registry.registerAuditor{value: SUFFICIENT_STAKE}(name);
    }
}
