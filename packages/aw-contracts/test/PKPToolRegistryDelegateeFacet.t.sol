// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import "../src/libraries/PKPToolRegistryDelegateeEvents.sol";
import "./mocks/MockPKPNFT.sol";

contract PKPToolRegistryDelegateeFacetTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    address nonOwner;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Test data
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    uint256 constant TEST_PKP_TOKEN_ID_2 = 2;
    address constant TEST_DELEGATEE = address(0x1234);
    address constant TEST_DELEGATEE_2 = address(0x5678);

    // Events to test
    event AddedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
    event RemovedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);

    function setUp() public {
        // Setup deployer account using default test account
        deployer = vm.addr(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        nonOwner = makeAddr("non-owner");

        // Deploy mock PKP NFT contract
        mockPkpNft = new MockPKPNFT();

        // Set environment variables for deployment
        vm.setEnv("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        
        // Deploy using the script
        deployScript = new DeployPKPToolRegistry();
        address diamondAddress = deployScript.deployToNetwork("test", address(mockPkpNft));
        diamond = PKPToolRegistry(payable(diamondAddress));

        // Set up mock PKP NFT for tests
        mockPkpNft.setOwner(TEST_PKP_TOKEN_ID, deployer);
        mockPkpNft.setOwner(TEST_PKP_TOKEN_ID_2, deployer);
    }

    /// @notice Test adding a single delegatee
    function test_addSingleDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Expect the AddedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit AddedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add the delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee was added
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be added"
        );

        // Verify PKP is in delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 1, "Wrong number of delegated PKPs");
        assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");

        vm.stopPrank();
    }

    /// @notice Test adding multiple delegatees
    function test_addMultipleDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;

        // Expect the AddedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit AddedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add the delegatees
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify both delegatees were added
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "First delegatee should be added"
        );
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE_2),
            "Second delegatee should be added"
        );

        // Verify PKP is in both delegatees' lists
        uint256[] memory delegatedPkps1 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps1.length, 1, "Wrong number of delegated PKPs for first delegatee");
        assertEq(delegatedPkps1[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID for first delegatee");

        uint256[] memory delegatedPkps2 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE_2);
        assertEq(delegatedPkps2.length, 1, "Wrong number of delegated PKPs for second delegatee");
        assertEq(delegatedPkps2[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID for second delegatee");

        vm.stopPrank();
    }

    /// @notice Test adding delegatee with empty array
    function test_revert_addEmptyDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](0);

        vm.expectRevert(PKPToolRegistryErrors.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test adding zero address as delegatee
    function test_revert_addZeroAddressDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = address(0);

        vm.expectRevert(PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test non-owner adding delegatee
    function test_revert_addDelegateeNonOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing a single delegatee
    function test_removeSingleDelegatee() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Expect the RemovedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit RemovedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Remove the delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee was removed
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be removed"
        );

        // Verify PKP is removed from delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 0, "Delegated PKPs should be empty");

        vm.stopPrank();
    }

    /// @notice Test removing multiple delegatees
    function test_removeMultipleDelegatees() public {
        vm.startPrank(deployer);

        // First add multiple delegatees
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Expect the RemovedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit RemovedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Remove the delegatees
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify both delegatees were removed
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "First delegatee should be removed"
        );
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE_2),
            "Second delegatee should be removed"
        );

        // Verify PKPs are removed from both delegatees' lists
        uint256[] memory delegatedPkps1 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps1.length, 0, "Delegated PKPs should be empty for first delegatee");

        uint256[] memory delegatedPkps2 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE_2);
        assertEq(delegatedPkps2.length, 0, "Delegated PKPs should be empty for second delegatee");

        vm.stopPrank();
    }

    /// @notice Test removing delegatee with empty array
    function test_revert_removeEmptyDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](0);

        vm.expectRevert(PKPToolRegistryErrors.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing zero address as delegatee
    function test_revert_removeZeroAddressDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = address(0);

        vm.expectRevert(PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test non-owner removing delegatee
    function test_revert_removeDelegateeNonOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing non-existent delegatee
    function test_removeNonExistentDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Should not revert, just silently succeed
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test adding same delegatee twice
    function test_addDelegateeTwice() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Add first time
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add second time - should succeed but not duplicate
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee is still added only once
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 1, "Should only have one delegated PKP");
        assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");

        // Verify getDelegatees also shows only one entry
        address[] memory retrievedDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(retrievedDelegatees.length, 1, "Should only have one delegatee");
        assertEq(retrievedDelegatees[0], TEST_DELEGATEE, "Wrong delegatee address");

        vm.stopPrank();
    }

    /// @notice Test adding delegatee to multiple PKPs
    function test_addDelegateeToPKPs() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Add to first PKP
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add to second PKP
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID_2, delegatees);

        // Verify delegatee is added to both PKPs
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be added to first PKP"
        );
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID_2, TEST_DELEGATEE),
            "Delegatee should be added to second PKP"
        );

        // Verify both PKPs are in delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 2, "Wrong number of delegated PKPs");
        assertTrue(
            delegatedPkps[0] == TEST_PKP_TOKEN_ID,
            "First PKP should be in delegated list"
        );
        assertTrue(
            delegatedPkps[1] == TEST_PKP_TOKEN_ID_2,
            "Second PKP should be in delegated list"
        );

        // Verify getDelegatees for first PKP
        address[] memory retrievedDelegatees1 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(retrievedDelegatees1.length, 1, "First PKP should have one delegatee");
        assertEq(retrievedDelegatees1[0], TEST_DELEGATEE, "Wrong delegatee for first PKP");

        // Verify getDelegatees for second PKP
        address[] memory retrievedDelegatees2 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID_2);
        assertEq(retrievedDelegatees2.length, 1, "Second PKP should have one delegatee");
        assertEq(retrievedDelegatees2[0], TEST_DELEGATEE, "Wrong delegatee for second PKP");

        vm.stopPrank();
    }

    /// @notice Test that adding duplicate delegatees doesn't include them in the event
    function test_addDuplicateDelegateeEvent() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](2);
        delegatees[0] = makeAddr("delegatee1");
        delegatees[1] = makeAddr("delegatee2");

        // Add delegatees first time
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Try to add both delegatees again, but only add a third new one
        address[] memory duplicateDelegatees = new address[](3);
        duplicateDelegatees[0] = delegatees[0]; // Already added
        duplicateDelegatees[1] = delegatees[1]; // Already added
        duplicateDelegatees[2] = makeAddr("delegatee3"); // New delegatee

        // Expect event to only include the new delegatee
        address[] memory expectedDelegatees = new address[](1);
        expectedDelegatees[0] = duplicateDelegatees[2];
        vm.expectEmit(true, false, false, true);
        emit AddedDelegatees(TEST_PKP_TOKEN_ID, expectedDelegatees);

        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, duplicateDelegatees);

        vm.stopPrank();
    }

    /// @notice Test that removing non-existent delegatees doesn't include them in the event
    function test_removeNonExistentDelegateeEvent() public {
        vm.startPrank(deployer);

        // Add one delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = makeAddr("delegatee1");
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Try to remove two delegatees, one that exists and one that doesn't
        address[] memory removeDelegatees = new address[](2);
        removeDelegatees[0] = delegatees[0]; // Exists
        removeDelegatees[1] = makeAddr("delegatee2"); // Doesn't exist

        // Expect event to only include the existing delegatee
        address[] memory expectedDelegatees = new address[](1);
        expectedDelegatees[0] = delegatees[0];
        vm.expectEmit(true, false, false, true);
        emit RemovedDelegatees(TEST_PKP_TOKEN_ID, expectedDelegatees);

        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, removeDelegatees);

        vm.stopPrank();
    }

    /// @notice Test that no event is emitted when no delegatees are modified
    function test_noEventWhenNoDelegateesModified() public {
        vm.startPrank(deployer);

        // Add two delegatees
        address[] memory delegatees = new address[](2);
        delegatees[0] = makeAddr("delegatee1");
        delegatees[1] = makeAddr("delegatee2");
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Record all events before our test operations
        vm.recordLogs();

        // Try to add the same delegatees again - should not emit event
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Try to remove non-existent delegatees - should not emit event
        address[] memory nonExistentDelegatees = new address[](1);
        nonExistentDelegatees[0] = makeAddr("non-existent-delegatee");
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, nonExistentDelegatees);

        // Verify no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0, "No events should have been emitted");

        vm.stopPrank();
    }

    /// @notice Test that removing a delegatee cleans up all their policies and permissions
    function test_cleanupDelegateePolicies() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add some tools and policies
        string[] memory toolCids = new string[](2);
        toolCids[0] = "tool1";
        toolCids[1] = "tool2";

        // Register tools
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolCids, true);

        // Set custom policies for both tools
        string[] memory policies = new string[](2);
        address[] memory delegateesMultiple = new address[](2);
        delegateesMultiple[0] = TEST_DELEGATEE;
        delegateesMultiple[1] = TEST_DELEGATEE;
        policies[0] = "policy1";
        policies[1] = "policy2";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            delegateesMultiple,
            policies,
            true
        );

        // Remove the delegatee which should trigger cleanup
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify policies are completely removed
        (string memory policy1After,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[0],
            delegateesMultiple[0]
        );
        (string memory policy2After,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[1],
            delegateesMultiple[1]
        );

        assertEq(bytes(policy1After).length, 0, "Policy 1 should be removed");
        assertEq(bytes(policy2After).length, 0, "Policy 2 should be removed");

        // Verify delegatee is removed from delegateesWithCustomPolicy for both tools
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy,
            bool[] memory hasBlanketPolicy
        ) = PKPToolRegistryToolFacet(address(diamond)).getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        assertEq(toolsWithPolicy.length, 0, "There should be no tools with policies");
        assertEq(delegateesWithPolicy.length, 0, "There should be no delegatees with policies");
        assertEq(hasBlanketPolicy.length, 0, "There should be no tools with blanket policies");

        // Verify tools are still registered
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(
            TEST_PKP_TOKEN_ID
        );
        assertEq(registeredTools.length, 2, "Tools should still be registered");
        assertEq(registeredTools[0], toolCids[0], "First tool should still be registered");
        assertEq(registeredTools[1], toolCids[1], "Second tool should still be registered");

        vm.stopPrank();
    }

    /// @notice Test that cleanup works correctly when delegatee has no policies
    function test_cleanupDelegateePolicies_NoPolicies() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add some tools but don't set any policies
        string[] memory toolCids = new string[](2);
        toolCids[0] = "tool1";
        toolCids[1] = "tool2";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolCids, true);

        // Remove the delegatee which should trigger cleanup
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify tools are still registered (removing delegatee shouldn't affect tool registration)
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(
            TEST_PKP_TOKEN_ID
        );
        assertEq(registeredTools.length, 2, "Tools should still be registered");
        assertEq(registeredTools[0], toolCids[0], "First tool should still be registered");
        assertEq(registeredTools[1], toolCids[1], "Second tool should still be registered");

        vm.stopPrank();
    }

    /// @notice Test that cleanup works correctly with multiple PKPs
    function test_cleanupDelegateePolicies_MultiplePKPs() public {
        vm.startPrank(deployer);

        // Add delegatee to both PKPs
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID_2, delegatees);

        // Add tools to both PKPs
        string[] memory toolCids = new string[](1);
        toolCids[0] = "tool1";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolCids, true);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID_2, toolCids, true);

        // Set policies for both PKPs
        string[] memory policies = new string[](1);
        policies[0] = "policy1";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            delegatees,
            policies,
            true
        );
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID_2,
            toolCids,
            delegatees,
            policies,
            true
        );

        // Remove delegatee from first PKP only
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify first PKP's policies are removed but second PKP's remain
        (string memory policy1After,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[0],
            TEST_DELEGATEE
        );
        (string memory policy2After,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID_2,
            toolCids[0],
            TEST_DELEGATEE
        );

        assertEq(bytes(policy1After).length, 0, "Policy for PKP 1 should be removed");
        assertEq(policy2After, policies[0], "Policy for PKP 2 should be unchanged");

        // Verify tools are still registered for both PKPs (removing delegatee shouldn't affect tool registration)
        string[] memory registeredTools1 = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(
            TEST_PKP_TOKEN_ID
        );
        string[] memory registeredTools2 = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(
            TEST_PKP_TOKEN_ID_2
        );

        assertEq(registeredTools1.length, 1, "Tool should still be registered for PKP 1");
        assertEq(registeredTools2.length, 1, "Tool should still be registered for PKP 2");
        assertEq(registeredTools1[0], toolCids[0], "Tool should still be registered for PKP 1");
        assertEq(registeredTools2[0], toolCids[0], "Tool should still be registered for PKP 2");

        vm.stopPrank();
    }

    /// @notice Test that policies are set correctly
    function test_policiesAreSetCorrectly() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add some tools and policies
        string[] memory toolCids = new string[](2);
        toolCids[0] = "tool1";
        toolCids[1] = "tool2";

        // Register tools
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolCids, true);

        // Set custom policies for both tools
        string[] memory policies = new string[](2);
        address[] memory delegateesMultiple = new address[](2);
        delegateesMultiple[0] = TEST_DELEGATEE;
        delegateesMultiple[1] = TEST_DELEGATEE;
        policies[0] = "policy1";
        policies[1] = "policy2";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            delegateesMultiple,
            policies,
            true
        );

        // Verify policies are set correctly
        (string memory policy1,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[0],
            delegateesMultiple[0]
        );
        (string memory policy2,) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[1],
            delegateesMultiple[1]
        );

        assertEq(policy1, policies[0], "Policy 1 should be set correctly");
        assertEq(policy2, policies[1], "Policy 2 should be set correctly");

        vm.stopPrank();
    }

    /// @notice Test that policies are disabled
    function test_policiesAreDisabled() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add some tools and policies
        string[] memory toolCids = new string[](2);
        toolCids[0] = "tool1";
        toolCids[1] = "tool2";

        // Register tools
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolCids, true);

        // Set custom policies for both tools
        string[] memory policies = new string[](2);
        address[] memory delegateesMultiple = new address[](2);
        delegateesMultiple[0] = TEST_DELEGATEE;
        delegateesMultiple[1] = TEST_DELEGATEE;
        policies[0] = "policy1";
        policies[1] = "policy2";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            delegateesMultiple,
            policies,
            true
        );

        // Verify policies are set and enabled initially
        (string memory policy1Before, bool enabled1Before) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[0],
            delegateesMultiple[0]
        );
        (string memory policy2Before, bool enabled2Before) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[1],
            delegateesMultiple[1]
        );
        assertEq(policy1Before, policies[0], "Policy 1 should be set correctly");
        assertEq(policy2Before, policies[1], "Policy 2 should be set correctly");
        assertTrue(enabled1Before, "Policy 1 should be enabled");
        assertTrue(enabled2Before, "Policy 2 should be enabled");

        // Disable the policies
        PKPToolRegistryPolicyFacet(address(diamond)).disableCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            delegateesMultiple
        );

        // Verify policies still exist but are disabled
        (string memory policy1After, bool enabled1After) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[0],
            delegateesMultiple[0]
        );
        (string memory policy2After, bool enabled2After) = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            toolCids[1],
            delegateesMultiple[1]
        );

        assertEq(policy1After, policies[0], "Policy 1 should still exist");
        assertEq(policy2After, policies[1], "Policy 2 should still exist");
        assertFalse(enabled1After, "Policy 1 should be disabled");
        assertFalse(enabled2After, "Policy 2 should be disabled");

        vm.stopPrank();
    }
} 