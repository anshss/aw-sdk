// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../mocks/MockPKPNFT.sol";
import "../helpers/TestHelper.sol";

contract PKPToolRegistryToolPolicyIntegrationTest is Test, TestHelper {
    function setUp() public override {
        super.setUp();
    }

    /// @notice Test getting registered tools and their policies
    function test_getRegisteredToolsAndPolicies() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatee
        address[] memory delegateesToAdd = new address[](2);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
            policyIpfsCids,
            true
        );

        // Get registered tools and policies
        (
            string[] memory registeredTools,
            string[][] memory delegateePolicyCids,
            address[] memory delegatees
        ) = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndPolicies(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(delegatees.length, 2, "Should have two delegatees");
        assertEq(delegateePolicyCids.length, 2, "Wrong number of delegatee policy arrays");
        assertEq(delegateePolicyCids[0].length, 1, "First tool should have one delegatee policy");
        assertEq(delegateePolicyCids[1].length, 0, "Second tool should have no delegatee policies");
        
        // Tools should be returned in registration order
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong first tool");
        assertEq(registeredTools[1], TEST_TOOL_CID_2, "Wrong second tool");
        
        // First tool should have delegatee policy, second should have no policy
        assertEq(delegateePolicyCids[0][0], TEST_POLICY_CID, "Wrong policy for first tool");
        assertEq(delegatees[0], TEST_DELEGATEE, "Wrong first delegatee");
        assertEq(delegatees[1], TEST_DELEGATEE_2, "Wrong second delegatee");

        vm.stopPrank();
    }

    /// @notice Test getting tools with policies
    function test_getToolsWithPolicy() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatee
        address[] memory delegateesToAdd = new address[](2);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
            policyIpfsCids,
            true
        );

        // Get tools with policies
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy
        ) = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithPolicy.length, 1, "Wrong number of tools with policy");
        assertEq(delegateesWithPolicy.length, 1, "Wrong number of delegatee arrays");
        assertEq(toolsWithPolicy[0], TEST_TOOL_CID, "Wrong tool");
        assertEq(delegateesWithPolicy[0].length, 1, "Should have one delegatee");
        assertEq(delegateesWithPolicy[0][0], TEST_DELEGATEE, "Wrong delegatee");

        vm.stopPrank();
    }

    /// @notice Test getting tools without policies
    function test_getToolsWithoutPolicy() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatee
        address[] memory delegateesToAdd = new address[](2);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
            policyIpfsCids,
            true
        );

        // Get tools without policies
        string[] memory toolsWithoutPolicy = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithoutPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithoutPolicy.length, 1, "Wrong number of tools without policy");
        assertEq(toolsWithoutPolicy[0], TEST_TOOL_CID_2, "Wrong tool");

        vm.stopPrank();
    }

    /// @notice Test removing policies when removing delegatee
    function test_removePolicies() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatee
        address[] memory delegateesToAdd = new address[](2);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policies for tools
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegateesToAdd,
            policyIpfsCids,
            true
        );

        // Remove the delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Verify policies were removed
        (string memory policy1, bool enabled1) = PKPToolRegistryPolicyFacet(address(diamond)).getToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(bytes(policy1).length, 0, "Policy 1 should be removed");
        assertFalse(enabled1, "Policy 1 should be disabled");

        (string memory policy2, bool enabled2) = PKPToolRegistryPolicyFacet(address(diamond)).getToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID_2,
            TEST_DELEGATEE
        );
        assertEq(bytes(policy2).length, 0, "Policy 2 should be removed");
        assertFalse(enabled2, "Policy 2 should be disabled");

        vm.stopPrank();
    }
} 