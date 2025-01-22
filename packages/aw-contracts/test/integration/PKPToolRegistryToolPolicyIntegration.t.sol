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
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;

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

        // Permit tools for delegatees
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegateesToAdd);

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
        PKPToolRegistryToolFacet.ToolInfoWithDelegateesAndPolicies[] memory toolsInfo = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredToolsAndDelegatees(TEST_PKP_TOKEN_ID);

        // Verify number of tools
        assertEq(toolsInfo.length, 2, "Wrong number of registered tools");

        // Verify first tool info (has policy)
        assertEq(toolsInfo[0].toolIpfsCid, TEST_TOOL_CID, "Wrong first tool CID");
        assertTrue(toolsInfo[0].toolEnabled, "First tool should be enabled");
        assertEq(toolsInfo[0].delegatees.length, 1, "Wrong number of delegatees for first tool");
        assertEq(toolsInfo[0].delegatees[0], TEST_DELEGATEE, "Wrong delegatee for first tool");
        assertEq(toolsInfo[0].delegateesPolicyIpfsCids[0], TEST_POLICY_CID, "Wrong policy CID for first tool");
        assertTrue(toolsInfo[0].delegateesPolicyEnabled[0], "First tool policy should be enabled");

        // Verify second tool info (no policy)
        assertEq(toolsInfo[1].toolIpfsCid, TEST_TOOL_CID_2, "Wrong second tool CID");
        assertTrue(toolsInfo[1].toolEnabled, "Second tool should be enabled");
        assertEq(toolsInfo[1].delegatees.length, 0, "Second tool should have no delegatees with policies");

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
        PKPToolRegistryToolFacet.ToolInfoWithDelegateesAndPolicies[] memory toolsWithPolicy = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithPolicy.length, 1, "Wrong number of tools with policy");
        assertEq(toolsWithPolicy[0].delegatees.length, 1, "Should have one delegatee");
        assertEq(toolsWithPolicy[0].delegatees[0], TEST_DELEGATEE, "Wrong delegatee");
        assertEq(toolsWithPolicy[0].delegateesPolicyIpfsCids[0], TEST_POLICY_CID, "Wrong policy CID");
        assertTrue(toolsWithPolicy[0].delegateesPolicyEnabled[0], "Policy should be enabled");

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
        PKPToolRegistryToolFacet.ToolInfoWithDelegatees[] memory toolsWithoutPolicy = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithoutPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithoutPolicy.length, 1, "Wrong number of tools without policy");
        assertEq(toolsWithoutPolicy[0].toolIpfsCid, TEST_TOOL_CID_2, "Wrong tool CID");
        assertTrue(toolsWithoutPolicy[0].toolEnabled, "Tool should be enabled");
        assertEq(toolsWithoutPolicy[0].delegatees.length, 0, "Tool should have no delegatees");

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
        string[] memory queryTools = new string[](2);
        queryTools[0] = TEST_TOOL_CID;
        queryTools[1] = TEST_TOOL_CID_2;
        address[] memory queryDelegatees = new address[](2);
        queryDelegatees[0] = TEST_DELEGATEE;
        queryDelegatees[1] = TEST_DELEGATEE_2;
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "", "Policy 1 should be empty");
        assertFalse(policies[0].enabled, "Policy 1 should be disabled");
        assertEq(policies[1].policyIpfsCid, "", "Policy 2 should be empty");
        assertFalse(policies[1].enabled, "Policy 2 should be disabled");

        vm.stopPrank();
    }
} 