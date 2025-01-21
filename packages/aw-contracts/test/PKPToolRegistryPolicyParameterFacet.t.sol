// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "./helpers/TestHelper.sol";
import "../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/libraries/PKPToolRegistryStorage.sol";
import "../src/abstract/PKPToolRegistryBase.sol";

contract PKPToolRegistryPolicyParameterFacetTest is TestHelper {
    PKPToolRegistryToolFacet toolFacet;
    PKPToolRegistryDelegateeFacet delegateeFacet;
    PKPToolRegistryPolicyParameterFacet policyParameterFacet;

    function setUp() public override {
        super.setUp();
        toolFacet = PKPToolRegistryToolFacet(address(diamond));
        delegateeFacet = PKPToolRegistryDelegateeFacet(address(diamond));
        policyParameterFacet = PKPToolRegistryPolicyParameterFacet(address(diamond));
        
        vm.startPrank(deployer);
        // Register a tool first
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolFacet.registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);
        // Add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        delegateeFacet.addDelegatees(TEST_PKP_TOKEN_ID, delegatees);
        vm.stopPrank();
    }

    function test_getToolPolicyParameters_EmptyInitially() public {
        (string[] memory paramNames, bytes[] memory paramValues) = policyParameterFacet.getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(paramNames.length, 0);
        assertEq(paramValues.length, 0);
    }

    function test_getToolPolicyParameters_AfterSetting() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](2);
        paramNames[0] = TEST_PARAM_NAME;
        paramNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory paramValues = new bytes[](2);
        paramValues[0] = TEST_PARAM_VALUE;
        paramValues[1] = TEST_PARAM_VALUE_2;

        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );
        vm.stopPrank();

        (string[] memory returnedNames, bytes[] memory returnedValues) = policyParameterFacet.getToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );

        assertEq(returnedNames.length, 2);
        assertEq(returnedValues.length, 2);
        assertEq(returnedNames[0], TEST_PARAM_NAME);
        assertEq(returnedNames[1], TEST_PARAM_NAME_2);
        assertEq(returnedValues[0], TEST_PARAM_VALUE);
        assertEq(returnedValues[1], TEST_PARAM_VALUE_2);
    }

    function test_getToolPolicyParameter_NonExistent() public {
        bytes memory value = policyParameterFacet.getToolPolicyParameter(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            TEST_PARAM_NAME
        );
        assertEq(value.length, 0);
    }

    function test_getToolPolicyParameter_AfterSetting() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](1);
        paramNames[0] = TEST_PARAM_NAME;
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = TEST_PARAM_VALUE;

        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );
        vm.stopPrank();

        bytes memory value = policyParameterFacet.getToolPolicyParameter(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            TEST_PARAM_NAME
        );
        assertEq(value, TEST_PARAM_VALUE);
    }

    function test_setToolPolicyParametersForDelegatee_NotOwner() public {
        string[] memory paramNames = new string[](1);
        paramNames[0] = TEST_PARAM_NAME;
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = TEST_PARAM_VALUE;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );
    }

    function test_setToolPolicyParametersForDelegatee_ArrayLengthMismatch() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](2);
        paramNames[0] = TEST_PARAM_NAME;
        paramNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = TEST_PARAM_VALUE;

        vm.expectRevert(LibPKPToolRegistryPolicyParameterFacet.ArrayLengthMismatch.selector);
        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );
        vm.stopPrank();
    }

    function test_setToolPolicyParametersForDelegatee_InvalidDelegatee() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](1);
        paramNames[0] = TEST_PARAM_NAME;
        bytes[] memory paramValues = new bytes[](1);
        paramValues[0] = TEST_PARAM_VALUE;

        vm.expectRevert(LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee.selector);
        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            address(0),
            paramNames,
            paramValues
        );
        vm.stopPrank();
    }

    function test_removeToolPolicyParametersForDelegatee() public {
        vm.startPrank(deployer);
        // First set some parameters
        string[] memory paramNames = new string[](2);
        paramNames[0] = TEST_PARAM_NAME;
        paramNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory paramValues = new bytes[](2);
        paramValues[0] = TEST_PARAM_VALUE;
        paramValues[1] = TEST_PARAM_VALUE_2;

        policyParameterFacet.setToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames,
            paramValues
        );

        // Now remove one parameter
        string[] memory paramsToRemove = new string[](1);
        paramsToRemove[0] = TEST_PARAM_NAME;

        policyParameterFacet.removeToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramsToRemove
        );
        vm.stopPrank();

        // Verify the parameter was removed
        bytes memory value = policyParameterFacet.getToolPolicyParameter(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            TEST_PARAM_NAME
        );
        assertEq(value.length, 0);

        // Verify the other parameter still exists
        value = policyParameterFacet.getToolPolicyParameter(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            TEST_PARAM_NAME_2
        );
        assertEq(value, TEST_PARAM_VALUE_2);
    }

    function test_removeToolPolicyParametersForDelegatee_NotOwner() public {
        string[] memory paramNames = new string[](1);
        paramNames[0] = TEST_PARAM_NAME;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        policyParameterFacet.removeToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
    }

    function test_removeToolPolicyParametersForDelegatee_InvalidDelegatee() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](1);
        paramNames[0] = TEST_PARAM_NAME;

        vm.expectRevert(LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee.selector);
        policyParameterFacet.removeToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            address(0),
            paramNames
        );
        vm.stopPrank();
    }

    function test_removeToolPolicyParametersForDelegatee_EmptyParameters() public {
        vm.startPrank(deployer);
        string[] memory paramNames = new string[](0);

        vm.expectRevert(LibPKPToolRegistryPolicyParameterFacet.InvalidPolicyParameters.selector);
        policyParameterFacet.removeToolPolicyParametersForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE,
            paramNames
        );
        vm.stopPrank();
    }
} 