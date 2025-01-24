// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
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

    /// @notice Test that policy parameters are properly cleaned up when removing and re-registering a tool
    function test_policyParameterCleanupOnToolRemoval() public {
        vm.startPrank(deployer);

        // Step 1: Register a tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Step 2: Add delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Step 3: Set policy for the tool and delegatee
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Step 4: Set policy parameter
        string[] memory paramNames = new string[](1);
        paramNames[0] = "maxAmount";
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = abi.encode(1000);
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Step 5: Remove the tool
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // After removing tool, all policy queries should revert with ToolNotFound
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        vm.expectRevert(abi.encodeWithSignature("ToolNotFound(string)", TEST_TOOL_CID));
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );

        // Step 6: Re-register the tool (note: skipping delegatee removal/re-adding)
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Step 7: Set policy again
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // After re-registering tool, policies should be empty
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, TEST_POLICY_CID, "Policy should be set");
        assertTrue(policies[0].enabled, "Policy should be enabled");

        // Verify parameters are empty before setting them again
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parametersBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getAllToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(parametersBeforeSet.length, 0, "Parameters should be empty before setting them again (getAllToolPolicyParameters)");

        // Also verify using getToolPolicyParameters - this should return an empty array since the parameter doesn't exist
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory specificParamsBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(specificParamsBeforeSet.length, 0, "Parameters should be empty before setting them again (getToolPolicyParameters)");

        // Step 8: Try to set the same parameter again - this should succeed
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Verify parameter was set correctly
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parameters = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(parameters.length, 1, "Wrong number of parameters");
        assertEq(parameters[0].name, "maxAmount", "Wrong parameter name");
        assertEq(abi.decode(parameters[0].value, (uint256)), 1000, "Wrong parameter value");

        vm.stopPrank();
    }

    /// @notice Test that policy parameters are properly cleaned up when removing and re-registering a tool, without removing the delegatee
    function test_policyParameterCleanupOnToolRemovalKeepDelegatee() public {
        vm.startPrank(deployer);

        // Step 1: Register a tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Step 2: Add delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Step 3: Set policy for the tool and delegatee
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Step 4: Set policy parameter
        string[] memory paramNames = new string[](1);
        paramNames[0] = "maxAmount";
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = abi.encode(1000);
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Step 5: Remove the tool
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // After removing tool, all policy queries should revert with ToolNotFound
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        vm.expectRevert(abi.encodeWithSignature("ToolNotFound(string)", TEST_TOOL_CID));
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );

        // Step 6: Re-register the tool (note: skipping delegatee removal/re-adding)
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Step 7: Set policy again
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // After re-registering tool, policies should be empty
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, TEST_POLICY_CID, "Policy should be set");
        assertTrue(policies[0].enabled, "Policy should be enabled");

        // Verify parameters are empty before setting them again
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parametersBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getAllToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(parametersBeforeSet.length, 0, "Parameters should be empty before setting them again (getAllToolPolicyParameters)");

        // Also verify using getToolPolicyParameters - this should return an empty array since the parameter doesn't exist
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory specificParamsBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(specificParamsBeforeSet.length, 0, "Parameters should be empty before setting them again (getToolPolicyParameters)");

        // Step 8: Try to set the same parameter again - this should succeed
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Verify parameter was set correctly
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parameters = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(parameters.length, 1, "Wrong number of parameters");
        assertEq(parameters[0].name, "maxAmount", "Wrong parameter name");
        assertEq(abi.decode(parameters[0].value, (uint256)), 1000, "Wrong parameter value");

        vm.stopPrank();
    }

    /// @notice Test that policy parameters are properly cleaned up when removing and re-registering a tool while keeping the delegatee
    function test_policyParameterCleanupOnToolRemovalWithExistingDelegatee() public {
        vm.startPrank(deployer);

        // First add a delegatee that will be kept throughout the test
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Now register a tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Set policy for the tool and existing delegatee
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Set a policy parameter
        string[] memory paramNames = new string[](1);
        paramNames[0] = "maxAmount";
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = abi.encode(1000);
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Remove the tool (delegatee remains)
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tool-related queries revert with ToolNotFound
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        vm.expectRevert(abi.encodeWithSignature("ToolNotFound(string)", TEST_TOOL_CID));
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );

        // Re-register the same tool
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Set the policy again for the existing delegatee
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Verify policy is set correctly
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, TEST_POLICY_CID, "Policy should be set");
        assertTrue(policies[0].enabled, "Policy should be enabled");

        // Verify parameters are empty
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parametersBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getAllToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(parametersBeforeSet.length, 0, "Parameters should be empty after tool re-registration");

        // Also verify using getToolPolicyParameters
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory specificParamsBeforeSet = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(specificParamsBeforeSet.length, 0, "Specific parameters should be empty after tool re-registration");

        // Set the same parameter again
        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Verify parameter was set correctly
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parameters = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        assertEq(parameters.length, 1, "Should have one parameter");
        assertEq(parameters[0].name, "maxAmount", "Parameter name should be maxAmount");
        assertEq(abi.decode(parameters[0].value, (uint256)), 1000, "Parameter value should be 1000");

        vm.stopPrank();
    }
} 