// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
import "../mocks/MockPKPNFT.sol";
import "../helpers/TestHelper.sol";

contract PKPToolRegistryLifecycleTest is Test, TestHelper {
    function setUp() public override {
        super.setUp();
    }

    /// @notice Test full lifecycle of PKP Tool Registry interactions
    function test_fullLifecycle() public {
        vm.startPrank(deployer);

        // Step 1: Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Verify tools are registered and enabled
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        
        (bool isRegistered1, bool isEnabled1) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        (bool isRegistered2, bool isEnabled2) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID_2);
        assertTrue(isRegistered1 && isEnabled1, "Tool 1 should be registered and enabled");
        assertTrue(isRegistered2 && isEnabled2, "Tool 2 should be registered and enabled");

        // Step 2: Add delegatees
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatees are added with individual checks
        address[] memory storedDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(storedDelegatees.length, 2, "Wrong number of delegatees");
        bool isDelegatee1 = PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE);
        bool isDelegatee2 = PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE_2);
        assertTrue(isDelegatee1, "First delegatee should be added");
        assertTrue(isDelegatee2, "Second delegatee should be added");

        // Step 3: Set delegatee-specific policies
        string[] memory singleToolArray = new string[](1);
        singleToolArray[0] = TEST_TOOL_CID;
        address[] memory singleDelegateeArray = new address[](1);
        singleDelegateeArray[0] = TEST_DELEGATEE;
        string[] memory delegateePolicies = new string[](1);
        delegateePolicies[0] = TEST_POLICY_CID_2;
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            singleToolArray,
            singleDelegateeArray,
            delegateePolicies,
            true
        );

        // Verify delegatee-specific policy is set
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory toolPolicies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(toolPolicies[0].policyIpfsCid, TEST_POLICY_CID_2, "Wrong delegatee policy");
        assertTrue(toolPolicies[0].enabled, "Policy should be enabled");

        // Step 4: Set delegatee-specific parameters
        string[] memory parameterNames = new string[](2);
        parameterNames[0] = TEST_PARAM_NAME;
        parameterNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory parameterValues = new bytes[](2);
        parameterValues[0] = TEST_PARAM_VALUE;
        parameterValues[1] = TEST_PARAM_VALUE_2;

        PKPToolRegistryPolicyParameterFacet(address(diamond)).setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            parameterNames,
            parameterValues
        );

        // Verify delegatee-specific parameters are set
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parameters = PKPToolRegistryPolicyParameterFacet(address(diamond)).getAllToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(parameters.length, 2, "Wrong number of delegatee parameters");
        assertEq(parameters[0].name, TEST_PARAM_NAME, "Wrong parameter name 1");
        assertEq(parameters[1].name, TEST_PARAM_NAME_2, "Wrong parameter name 2");
        assertEq(parameters[0].value, TEST_PARAM_VALUE, "Wrong delegatee parameter value 1");
        assertEq(parameters[1].value, TEST_PARAM_VALUE_2, "Wrong delegatee parameter value 2");

        // Verify individual parameter retrieval
        PKPToolRegistryPolicyParameterFacet.Parameter[] memory parameters2 = PKPToolRegistryPolicyParameterFacet(address(diamond)).getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            parameterNames
        );
        assertEq(parameters2[0].value, TEST_PARAM_VALUE, "Wrong individual parameter value");
        assertEq(parameters2[1].value, TEST_PARAM_VALUE_2, "Wrong individual parameter value");

        // Step 5: Disable policies
        PKPToolRegistryPolicyFacet(address(diamond)).disableToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            singleToolArray,
            singleDelegateeArray
        );

        // Verify policies are disabled
        toolPolicies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertFalse(toolPolicies[0].enabled, "Policy should be disabled");

        // Step 6: Remove parameters
        string[] memory paramsToRemove = new string[](1);
        paramsToRemove[0] = TEST_PARAM_NAME;
        PKPToolRegistryPolicyParameterFacet(address(diamond)).removeToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramsToRemove
        );

        // Verify parameters are removed
        parameters = PKPToolRegistryPolicyParameterFacet(address(diamond)).getAllToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(parameters.length, 1, "Should have 1 delegatee parameter remaining");
        assertEq(parameters[0].name, TEST_PARAM_NAME_2, "Wrong remaining parameter name");
        assertEq(parameters[0].value, TEST_PARAM_VALUE_2, "Wrong remaining parameter value");

        // Step 7: Remove delegatees
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatees are removed
        storedDelegatees = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatees(TEST_PKP_TOKEN_ID);
        assertEq(storedDelegatees.length, 0, "All delegatees should be removed");

        // Step 8: Remove tools
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tools are removed
        registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 0, "All tools should be removed");

        vm.stopPrank();
    }
} 