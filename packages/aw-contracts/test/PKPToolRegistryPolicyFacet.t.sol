// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "./helpers/TestHelper.sol";

contract PKPToolRegistryPolicyFacetTest is Test, TestHelper {
    function setUp() public override {
        super.setUp();
    }

    /// @notice Helper function to register tools for testing
    function _registerTools(string[] memory toolIpfsCids) internal {
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);
    }

    /// @notice Test getting a non-existent tool policy
    function test_getToolPolicyForDelegatee_NonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(abi.encodeWithSelector(
            LibPKPToolRegistryPolicyFacet.ToolNotFound.selector,
            TEST_TOOL_CID
        ));
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        vm.stopPrank();
    }

    /// @notice Test getting policy with empty tool CID
    function test_getToolPolicyForDelegatee_EmptyToolCid() public {
        vm.startPrank(deployer);

        string[] memory emptyToolCids = new string[](1);
        emptyToolCids[0] = "";
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(LibPKPToolRegistryPolicyFacet.EmptyIPFSCID.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            emptyToolCids,
            delegatees
        );

        vm.stopPrank();
    }

    /// @notice Test getting policy with zero address delegatee
    function test_getToolPolicyForDelegatee_ZeroAddressDelegatee() public {
        vm.startPrank(deployer);

        string[] memory toolCids = new string[](1);
        toolCids[0] = TEST_TOOL_CID;
        address[] memory zeroDelegatees = new address[](1);
        zeroDelegatees[0] = address(0);

        vm.expectRevert(LibPKPToolRegistryPolicyFacet.InvalidDelegatee.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolCids,
            zeroDelegatees
        );

        vm.stopPrank();
    }

    /// @notice Test setting a single tool policy successfully
    function test_setToolPoliciesForDelegatees_Single() public {
        vm.startPrank(deployer);

        // Register tool first
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        _registerTools(toolIpfsCids);

        // Set policy
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesSet(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees, policyIpfsCids, true);
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Verify policy was set
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, TEST_POLICY_CID, "Wrong policy CID");
        assertTrue(policies[0].enabled, "Policy should be enabled");
        assertEq(policies[0].delegatee, TEST_DELEGATEE, "Wrong delegatee for policy");

        vm.stopPrank();
    }

    /// @notice Test setting multiple tool policies successfully
    function test_setToolPoliciesForDelegatees_Multiple() public {
        vm.startPrank(deployer);

        // Register tools first
        string[] memory toolIpfsCids = new string[](3);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        toolIpfsCids[2] = TEST_TOOL_CID_3;
        _registerTools(toolIpfsCids);

        // Set policies
        address[] memory delegatees = new address[](3);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        delegatees[2] = TEST_DELEGATEE_3;
        string[] memory policyIpfsCids = new string[](3);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;
        policyIpfsCids[2] = TEST_POLICY_CID_3;

        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesSet(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees, policyIpfsCids, true);
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Verify all policies were set
        for (uint256 i = 0; i < toolIpfsCids.length; i++) {
            string[] memory queryTools = new string[](1);
            queryTools[0] = toolIpfsCids[i];
            address[] memory queryDelegatees = new address[](1);
            queryDelegatees[0] = delegatees[i];
            
            PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
                TEST_PKP_TOKEN_ID,
                queryTools,
                queryDelegatees
            );
            assertEq(policies[0].policyIpfsCid, policyIpfsCids[i], "Wrong policy CID");
            assertTrue(policies[0].enabled, "Policy should be enabled");
            assertEq(policies[0].delegatee, delegatees[i], "Wrong delegatee for policy");
        }

        vm.stopPrank();
    }

    /// @notice Test setting policies with array length mismatch
    function test_setToolPoliciesForDelegatees_ArrayLengthMismatch() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        vm.expectRevert(LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        vm.stopPrank();
    }

    /// @notice Test setting policies by non-owner
    function test_setToolPoliciesForDelegatees_NotOwner() public {
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        vm.stopPrank();
    }

    /// @notice Test removing a single tool policy successfully
    function test_removeToolPoliciesForDelegatees_Single() public {
        vm.startPrank(deployer);

        // Register tool and set policy first
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Remove policy
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesRemoved(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);
        PKPToolRegistryPolicyFacet(address(diamond)).removeToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policy was removed
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;
        
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "", "Policy should be empty");
        assertFalse(policies[0].enabled, "Policy should be disabled");
        assertEq(policies[0].delegatee, TEST_DELEGATEE, "Wrong delegatee for policy");

        vm.stopPrank();
    }

    /// @notice Test removing multiple tool policies successfully
    function test_removeToolPoliciesForDelegatees_Multiple() public {
        vm.startPrank(deployer);

        // Register tools and set policies first
        string[] memory toolIpfsCids = new string[](3);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        toolIpfsCids[2] = TEST_TOOL_CID_3;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](3);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        delegatees[2] = TEST_DELEGATEE_3;
        string[] memory policyIpfsCids = new string[](3);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;
        policyIpfsCids[2] = TEST_POLICY_CID_3;

        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Remove policies
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesRemoved(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);
        PKPToolRegistryPolicyFacet(address(diamond)).removeToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify all policies were removed
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;

        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "", "Policy should be empty");
        assertFalse(policies[0].enabled, "Policy should be disabled");
        assertEq(policies[0].delegatee, TEST_DELEGATEE, "Wrong delegatee for policy");

        vm.stopPrank();
    }

    /// @notice Test enabling tool policies successfully
    function test_enableToolPoliciesForDelegatees() public {
        vm.startPrank(deployer);

        // Register tools and set policies first
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        // Set policies but don't enable them
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            false
        );

        // Enable policies
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.PoliciesEnabled(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);
        PKPToolRegistryPolicyFacet(address(diamond)).enableToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policies are enabled
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;

        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, policyIpfsCids[0], "Wrong policy CID");
        assertTrue(policies[0].enabled, "Policy should be enabled");
        assertEq(policies[0].delegatee, TEST_DELEGATEE, "Wrong delegatee for policy");

        vm.stopPrank();
    }

    /// @notice Test disabling tool policies successfully
    function test_disableToolPoliciesForDelegatees() public {
        vm.startPrank(deployer);

        // Register tools and set policies first
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        // Set and enable policies
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Disable policies
        vm.expectEmit(true, false, false, true);
        emit LibPKPToolRegistryPolicyFacet.PoliciesDisabled(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);
        PKPToolRegistryPolicyFacet(address(diamond)).disableToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policies are disabled but still exist
        string[] memory queryTools = new string[](1);
        queryTools[0] = TEST_TOOL_CID;
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = TEST_DELEGATEE;

        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, policyIpfsCids[0], "Wrong policy CID");
        assertFalse(policies[0].enabled, "Policy should be disabled");
        assertEq(policies[0].delegatee, TEST_DELEGATEE, "Wrong delegatee for policy");

        vm.stopPrank();
    }

    /// @notice Test enabling non-existent policy
    function test_enableToolPoliciesForDelegatees_NoPolicySet() public {
        vm.startPrank(deployer);

        // Register tool but don't set policy
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(abi.encodeWithSelector(
            LibPKPToolRegistryPolicyFacet.NoPolicySet.selector,
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        ));
        PKPToolRegistryPolicyFacet(address(diamond)).enableToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        vm.stopPrank();
    }

    /// @notice Test disabling non-existent policy
    function test_disableToolPoliciesForDelegatees_NoPolicySet() public {
        vm.startPrank(deployer);

        // Register tool but don't set policy
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        _registerTools(toolIpfsCids);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(abi.encodeWithSelector(
            LibPKPToolRegistryPolicyFacet.NoPolicySet.selector,
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        ));
        PKPToolRegistryPolicyFacet(address(diamond)).disableToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        vm.stopPrank();
    }
} 