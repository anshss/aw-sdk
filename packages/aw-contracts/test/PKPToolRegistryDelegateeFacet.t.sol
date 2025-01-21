// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "./helpers/TestHelper.sol";

contract PKPToolRegistryDelegateeFacetTest is Test, TestHelper {
    function setUp() public override {
        super.setUp();
    }

    /// @notice Test adding a single delegatee successfully
    function test_addSingleDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;

        // Add delegatee
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryDelegateeFacet.AddedDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Verify delegatee was added
        address[] memory delegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(delegatees.length, 1, "Wrong number of delegatees");
        assertEq(delegatees[0], TEST_DELEGATEE, "Wrong delegatee");

        // Verify PKP is in delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 1, "Wrong number of delegated PKPs");
        assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");

        vm.stopPrank();
    }

    /// @notice Test adding multiple delegatees successfully
    function test_addMultipleDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegateesToAdd = new address[](3);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        delegateesToAdd[2] = TEST_DELEGATEE_3;

        // Add delegatees
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryDelegateeFacet.AddedDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Verify delegatees were added
        address[] memory delegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(delegatees.length, 3, "Wrong number of delegatees");
        
        // Verify each delegatee has the PKP in their list
        for (uint256 i = 0; i < delegateesToAdd.length; i++) {
            uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(delegateesToAdd[i]);
            assertEq(delegatedPkps.length, 1, "Wrong number of delegated PKPs");
            assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");
        }

        vm.stopPrank();
    }

    /// @notice Test adding delegatee with empty array reverts
    function test_addDelegatees_EmptyArray() public {
        vm.startPrank(deployer);

        address[] memory delegateesToAdd = new address[](0);

        vm.expectRevert(LibPKPToolRegistryDelegateeFacet.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        vm.stopPrank();
    }

    /// @notice Test adding zero address as delegatee reverts
    function test_addDelegatees_ZeroAddress() public {
        vm.startPrank(deployer);

        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = address(0);

        vm.expectRevert(LibPKPToolRegistryDelegateeFacet.InvalidDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        vm.stopPrank();
    }

    /// @notice Test adding same delegatee twice reverts
    function test_addDelegatees_AlreadyExists() public {
        vm.startPrank(deployer);

        // Add delegatee first time
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Try to add same delegatee again
        vm.expectRevert(abi.encodeWithSelector(
            LibPKPToolRegistryDelegateeFacet.DelegateeAlreadyExists.selector,
            TEST_PKP_TOKEN_ID,
            TEST_DELEGATEE
        ));
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        vm.stopPrank();
    }

    /// @notice Test adding delegatee by non-owner reverts
    function test_addDelegatees_NotOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        vm.stopPrank();
    }

    /// @notice Test removing a single delegatee successfully
    function test_removeSingleDelegatee() public {
        vm.startPrank(deployer);

        // Add delegatee first
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Remove delegatee
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryDelegateeFacet.RemovedDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Verify delegatee was removed
        address[] memory delegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(delegatees.length, 0, "Wrong number of delegatees");

        // Verify PKP is removed from delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 0, "Wrong number of delegated PKPs");

        vm.stopPrank();
    }

    /// @notice Test removing multiple delegatees successfully
    function test_removeMultipleDelegatees() public {
        vm.startPrank(deployer);

        // Add delegatees first
        address[] memory delegateesToAdd = new address[](3);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        delegateesToAdd[2] = TEST_DELEGATEE_3;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Remove delegatees
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryDelegateeFacet.RemovedDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Verify all delegatees were removed
        address[] memory delegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(delegatees.length, 0, "Wrong number of delegatees");

        // Verify PKP is removed from all delegatees' lists
        for (uint256 i = 0; i < delegateesToAdd.length; i++) {
            uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(delegateesToAdd[i]);
            assertEq(delegatedPkps.length, 0, "Wrong number of delegated PKPs");
        }

        vm.stopPrank();
    }

    /// @notice Test removing delegatee with empty array reverts
    function test_removeDelegatees_EmptyArray() public {
        vm.startPrank(deployer);

        address[] memory delegateesToRemove = new address[](0);

        vm.expectRevert(LibPKPToolRegistryDelegateeFacet.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToRemove);

        vm.stopPrank();
    }

    /// @notice Test removing zero address as delegatee reverts
    function test_removeDelegatees_ZeroAddress() public {
        vm.startPrank(deployer);

        address[] memory delegateesToRemove = new address[](1);
        delegateesToRemove[0] = address(0);

        vm.expectRevert(LibPKPToolRegistryDelegateeFacet.InvalidDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToRemove);

        vm.stopPrank();
    }

    /// @notice Test removing non-existent delegatee reverts
    function test_removeDelegatees_NotFound() public {
        vm.startPrank(deployer);

        address[] memory delegateesToRemove = new address[](1);
        delegateesToRemove[0] = TEST_DELEGATEE;

        vm.expectRevert(abi.encodeWithSelector(
            LibPKPToolRegistryDelegateeFacet.DelegateeNotFound.selector,
            TEST_PKP_TOKEN_ID,
            TEST_DELEGATEE
        ));
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToRemove);

        vm.stopPrank();
    }

    /// @notice Test removing delegatee by non-owner reverts
    function test_removeDelegatees_NotOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegateesToRemove = new address[](1);
        delegateesToRemove[0] = TEST_DELEGATEE;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToRemove);

        vm.stopPrank();
    }

    /// @notice Test checking if address is a delegatee
    function test_isPkpDelegatee() public {
        vm.startPrank(deployer);

        // Initially should return false
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Should not be delegatee initially"
        );

        // Add delegatee
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Should now return true
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Should be delegatee after adding"
        );

        // Remove delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Should return false again
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Should not be delegatee after removing"
        );

        vm.stopPrank();
    }

    /// @notice Test getting delegatees for a PKP
    function test_getDelegatees() public {
        vm.startPrank(deployer);

        // Initially should be empty
        address[] memory initialDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(initialDelegatees.length, 0, "Should have no delegatees initially");

        // Add multiple delegatees
        address[] memory delegateesToAdd = new address[](3);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        delegateesToAdd[2] = TEST_DELEGATEE_3;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Check all delegatees are present
        address[] memory currentDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(currentDelegatees.length, 3, "Should have three delegatees");

        // Remove one delegatee
        address[] memory delegateesToRemove = new address[](1);
        delegateesToRemove[0] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToRemove);

        // Check remaining delegatees
        address[] memory remainingDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(remainingDelegatees.length, 2, "Should have two delegatees");

        vm.stopPrank();
    }

    /// @notice Test getting delegated PKPs for an address
    function test_getDelegatedPkps() public {
        vm.startPrank(deployer);

        // Initially should be empty
        uint256[] memory initialPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(initialPkps.length, 0, "Should have no delegated PKPs initially");

        // Add delegatee to first PKP
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Add delegatee to second PKP
        uint256 secondPkpTokenId = TEST_PKP_TOKEN_ID + 1;
        mockPkpNft.setOwner(secondPkpTokenId, deployer);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(secondPkpTokenId, delegateesToAdd);

        // Check both PKPs are present
        uint256[] memory currentPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(currentPkps.length, 2, "Should have two delegated PKPs");

        // Remove delegatee from first PKP
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Check remaining PKP
        uint256[] memory remainingPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(remainingPkps.length, 1, "Should have one delegated PKP");
        assertEq(remainingPkps[0], secondPkpTokenId, "Wrong remaining PKP");

        vm.stopPrank();
    }
} 