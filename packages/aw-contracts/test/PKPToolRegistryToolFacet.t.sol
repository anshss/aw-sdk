// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "./helpers/TestHelper.sol";

contract PKPToolRegistryToolFacetTest is Test, TestHelper {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;

    // Events from the contract
    event ToolsRegistered(uint256 indexed pkpTokenId, bool enabled, string[] toolIpfsCids);
    event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsPermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event ToolsUnpermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);

    function setUp() public override {
        super.setUp();
    }

    /// @notice Test registering a single tool
    function test_registerSingleTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Expect the ToolsRegistered event
        vm.expectEmit(true, true, true, true);
        emit ToolsRegistered(TEST_PKP_TOKEN_ID, true, toolIpfsCids);

        // Register the tool
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Verify registration
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 1, "Wrong number of registered tools");
        assertEq(registeredTools[0].toolIpfsCid, TEST_TOOL_CID, "Wrong tool CID registered");
        assertTrue(registeredTools[0].toolEnabled, "Tool should be enabled");
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should be registered");
        assertTrue(isEnabled, "Tool should be enabled");

        vm.stopPrank();
    }

    /// @notice Test registering multiple tools
    function test_registerMultipleTools() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;

        // Expect the ToolsRegistered event
        vm.expectEmit(true, true, true, true);
        emit ToolsRegistered(TEST_PKP_TOKEN_ID, true, toolIpfsCids);

        // Register the tools
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Verify registration
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(registeredTools[0].toolIpfsCid, TEST_TOOL_CID, "Wrong first tool CID registered");
        assertEq(registeredTools[1].toolIpfsCid, TEST_TOOL_CID_2, "Wrong second tool CID registered");
        assertTrue(registeredTools[0].toolEnabled, "Tool should be enabled");
        assertTrue(registeredTools[1].toolEnabled, "Tool should be enabled");

        for (uint256 i = 0; i < toolIpfsCids.length; i++) {
            (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, toolIpfsCids[i]);
            assertTrue(isRegistered, "Tool should be registered");
            assertTrue(isEnabled, "Tool should be enabled");
        }

        vm.stopPrank();
    }

    /// @notice Test registering a tool with empty IPFS CID
    function test_revert_registerEmptyIPFSCID() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "";

        vm.expectRevert(LibPKPToolRegistryToolFacet.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        vm.stopPrank();
    }

    /// @notice Test registering a duplicate tool
    function test_revert_registerDuplicateTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Register first time
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Try to register same tool again
        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryToolFacet.ToolAlreadyRegistered.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        vm.stopPrank();
    }

    /// @notice Test removing a single tool
    function test_removeSingleTool() public {
        vm.startPrank(deployer);

        // First register a tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Expect the ToolsRemoved event
        vm.expectEmit(true, true, true, true);
        emit ToolsRemoved(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Remove the tool
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify removal
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 0, "Tool was not removed");

        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegistered, "Tool should not be registered");
        assertFalse(isEnabled, "Tool should not be enabled");

        vm.stopPrank();
    }

    /// @notice Test removing multiple tools
    function test_removeMultipleTools() public {
        vm.startPrank(deployer);

        // First register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Expect the ToolsRemoved event
        vm.expectEmit(true, true, true, true);
        emit ToolsRemoved(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Remove the tools
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify removal
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 0, "Tools were not removed");

        for (uint256 i = 0; i < toolIpfsCids.length; i++) {
            (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, toolIpfsCids[i]);
            assertFalse(isRegistered, "Tool should not be registered");
            assertFalse(isEnabled, "Tool should not be enabled");
        }

        vm.stopPrank();
    }

    /// @notice Test removing a non-existent tool
    function test_revert_removeNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryToolFacet.ToolNotFound.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test enabling a single tool
    function test_enableSingleTool() public {
        vm.startPrank(deployer);

        // First register a tool (disabled)
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, false);

        // Verify tool is registered but disabled
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should be registered");
        assertFalse(isEnabled, "Tool should be disabled after registration");

        // Expect the ToolsEnabled event
        vm.expectEmit(true, true, true, true);
        emit ToolsEnabled(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Enable the tool
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tool is enabled
        (isRegistered, isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should still be registered");
        assertTrue(isEnabled, "Tool should be enabled");

        vm.stopPrank();
    }

    /// @notice Test enabling multiple tools
    function test_enableMultipleTools() public {
        vm.startPrank(deployer);

        // Register tools first (disabled)
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, false);

        // Verify tools are registered but disabled
        (bool isRegistered1, bool isEnabled1) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        (bool isRegistered2, bool isEnabled2) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID_2);
        assertTrue(isRegistered1, "Tool 1 should be registered");
        assertTrue(isRegistered2, "Tool 2 should be registered");
        assertFalse(isEnabled1, "Tool 1 should be disabled");
        assertFalse(isEnabled2, "Tool 2 should be disabled");

        // Enable the tools
        vm.expectEmit(true, true, true, true);
        emit ToolsEnabled(TEST_PKP_TOKEN_ID, toolIpfsCids);

        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tools are enabled
        (isRegistered1, isEnabled1) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        (isRegistered2, isEnabled2) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID_2);
        assertTrue(isRegistered1, "Tool 1 should still be registered");
        assertTrue(isRegistered2, "Tool 2 should still be registered");
        assertTrue(isEnabled1, "Tool 1 should be enabled");
        assertTrue(isEnabled2, "Tool 2 should be enabled");

        vm.stopPrank();
    }

    /// @notice Test enabling a non-existent tool
    function test_revert_enableNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryToolFacet.ToolNotFound.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test disabling a single tool
    function test_disableSingleTool() public {
        vm.startPrank(deployer);

        // First register a tool (enabled)
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Verify tool is registered and enabled
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should be registered");
        assertTrue(isEnabled, "Tool should be enabled after registration");

        // Expect the ToolsDisabled event
        vm.expectEmit(true, true, true, true);
        emit ToolsDisabled(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Disable the tool
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tool is disabled but still registered
        (isRegistered, isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should still be registered");
        assertFalse(isEnabled, "Tool should be disabled");

        vm.stopPrank();
    }

    /// @notice Test disabling multiple tools
    function test_disableMultipleTools() public {
        vm.startPrank(deployer);

        // Register tools first (enabled)
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Verify tools are registered and enabled
        (bool isRegistered1, bool isEnabled1) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        (bool isRegistered2, bool isEnabled2) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID_2);
        assertTrue(isRegistered1, "Tool 1 should be registered");
        assertTrue(isRegistered2, "Tool 2 should be registered");
        assertTrue(isEnabled1, "Tool 1 should be enabled");
        assertTrue(isEnabled2, "Tool 2 should be enabled");

        // Disable the tools
        vm.expectEmit(true, true, true, true);
        emit ToolsDisabled(TEST_PKP_TOKEN_ID, toolIpfsCids);

        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify tools are disabled
        (isRegistered1, isEnabled1) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        (isRegistered2, isEnabled2) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID_2);
        assertTrue(isRegistered1, "Tool 1 should still be registered");
        assertTrue(isRegistered2, "Tool 2 should still be registered");
        assertFalse(isEnabled1, "Tool 1 should be disabled");
        assertFalse(isEnabled2, "Tool 2 should be disabled");

        vm.stopPrank();
    }

    /// @notice Test disabling a non-existent tool
    function test_revert_disableNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryToolFacet.ToolNotFound.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test permitting a tool for a delegatee
    function test_permitToolForDelegatee() public {
        vm.startPrank(deployer);

        // Register tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Expect the ToolsPermitted event
        vm.expectEmit(true, true, true, true);
        emit ToolsPermitted(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Permit the tool
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Verify permission
        (bool isPermitted, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolPermittedForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertTrue(isPermitted, "Tool should be permitted");
        assertTrue(isEnabled, "Tool should be enabled");

        vm.stopPrank();
    }

    /// @notice Test unpermitting a tool for a delegatee
    function test_unpermitToolForDelegatee() public {
        vm.startPrank(deployer);

        // Register tool and add delegatee
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // First permit the tool
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Expect the ToolsUnpermitted event
        vm.expectEmit(true, true, true, true);
        emit ToolsUnpermitted(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Unpermit the tool
        PKPToolRegistryToolFacet(address(diamond)).unpermitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Verify permission was removed
        (bool isPermitted, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolPermittedForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertFalse(isPermitted, "Tool should not be permitted");
        assertTrue(isEnabled, "Tool should still be enabled");

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot register tools
    function test_revert_nonOwnerRegister() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot remove tools
    function test_revert_nonOwnerRemove() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot enable tools
    function test_revert_nonOwnerEnable() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot disable tools
    function test_revert_nonOwnerDisable() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot permit tools
    function test_revert_nonOwnerPermit() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        vm.stopPrank();
    }

    /// @notice Test that non-owner cannot unpermit tools
    function test_revert_nonOwnerUnpermit() public {
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).unpermitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        vm.stopPrank();
    }

    /// @notice Test getting registered tools and their policies
    function test_getRegisteredToolsAndDelegatees() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;

        // Register first tool
        string[] memory firstToolIpfsCids = new string[](1);
        firstToolIpfsCids[0] = toolIpfsCids[0];
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, firstToolIpfsCids, true);

        // Register second tool and disable by default
        string[] memory secondToolIpfsCids = new string[](1);
        secondToolIpfsCids[0] = toolIpfsCids[1];
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, secondToolIpfsCids, false);

        // Add delegatees
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Permit tools for delegatees
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Set policies for tools and delegatees
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        // Set policies for first tool
        string[] memory firstToolPolicyIpfsCids = new string[](1);
        firstToolPolicyIpfsCids[0] = policyIpfsCids[0];
        address[] memory firstToolDelegatees = new address[](1);
        firstToolDelegatees[0] = delegatees[0];
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            firstToolIpfsCids,
            firstToolDelegatees,
            firstToolPolicyIpfsCids,
            true
        );

        // Set policies for second tool
        string[] memory secondToolPolicyIpfsCids = new string[](1);
        secondToolPolicyIpfsCids[0] = policyIpfsCids[1];
        address[] memory secondToolDelegatees = new address[](1);
        secondToolDelegatees[0] = delegatees[1];
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            secondToolIpfsCids,
            secondToolDelegatees,
            secondToolPolicyIpfsCids,
            false
        );

        // Get registered tools and policies
        PKPToolRegistryToolFacet.ToolInfoWithDelegateesAndPolicies[] memory toolsInfo = PKPToolRegistryToolFacet(address(diamond)).getAllRegisteredToolsAndDelegatees(TEST_PKP_TOKEN_ID);

        // Verify number of tools
        assertEq(toolsInfo.length, 2, "Wrong number of registered tools");

        // Verify first tool info
        assertEq(toolsInfo[0].toolIpfsCid, TEST_TOOL_CID, "Wrong first tool CID");
        assertTrue(toolsInfo[0].toolEnabled, "First tool should be enabled");
        assertEq(toolsInfo[0].delegatees.length, 1, "Wrong number of delegatees for first tool");
        assertEq(toolsInfo[0].delegatees[0], TEST_DELEGATEE, "Wrong delegatee for first tool");
        assertEq(toolsInfo[0].delegateesPolicyIpfsCids[0], TEST_POLICY_CID, "Wrong policy CID for first tool");
        assertTrue(toolsInfo[0].delegateesPolicyEnabled[0], "First tool policy should be enabled");

        // Verify second tool info
        assertEq(toolsInfo[1].toolIpfsCid, TEST_TOOL_CID_2, "Wrong second tool CID");
        assertFalse(toolsInfo[1].toolEnabled, "Second tool should be disabled");
        assertEq(toolsInfo[1].delegatees.length, 1, "Wrong number of delegatees for second tool");
        assertEq(toolsInfo[1].delegatees[0], TEST_DELEGATEE_2, "Wrong delegatee for second tool");
        assertEq(toolsInfo[1].delegateesPolicyIpfsCids[0], TEST_POLICY_CID_2, "Wrong policy CID for second tool");
        assertFalse(toolsInfo[1].delegateesPolicyEnabled[0], "Second tool policy should be disabled");

        vm.stopPrank();
    }

    function test_getToolsWithPolicy() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatees
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
        assertEq(toolsWithPolicy[0].toolIpfsCid, TEST_TOOL_CID, "Wrong tool CID");
        assertTrue(toolsWithPolicy[0].toolEnabled, "Tool should be enabled");
        assertEq(toolsWithPolicy[0].delegatees.length, 1, "Should have one delegatee");
        assertEq(toolsWithPolicy[0].delegatees[0], TEST_DELEGATEE, "Wrong delegatee");
        assertEq(toolsWithPolicy[0].delegateesPolicyIpfsCids[0], TEST_POLICY_CID, "Wrong policy CID");
        assertTrue(toolsWithPolicy[0].delegateesPolicyEnabled[0], "Policy should be enabled");

        vm.stopPrank();
    }

    function test_getToolsWithoutPolicy() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatees
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

    function test_getRegisteredToolAndDelegatees() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add delegatees
        address[] memory delegateesToAdd = new address[](2);
        delegateesToAdd[0] = TEST_DELEGATEE;
        delegateesToAdd[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Permit tools for delegatees
        PKPToolRegistryToolFacet(address(diamond)).permitToolsForDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCids, delegateesToAdd);

        // Set policies for first tool
        string[] memory firstToolIpfsCids = new string[](1);
        firstToolIpfsCids[0] = toolIpfsCids[0];
        string[] memory firstToolPolicyIpfsCids = new string[](1);
        firstToolPolicyIpfsCids[0] = TEST_POLICY_CID;
        address[] memory firstToolDelegatees = new address[](1);
        firstToolDelegatees[0] = delegateesToAdd[0];
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            firstToolIpfsCids,
            firstToolDelegatees,
            firstToolPolicyIpfsCids,
            true
        );

        // Set policies for second tool
        string[] memory secondToolIpfsCids = new string[](1);
        secondToolIpfsCids[0] = toolIpfsCids[1];
        string[] memory secondToolPolicyIpfsCids = new string[](1);
        secondToolPolicyIpfsCids[0] = TEST_POLICY_CID_2;
        address[] memory secondToolDelegatees = new address[](1);
        secondToolDelegatees[0] = delegateesToAdd[1];
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            secondToolIpfsCids,
            secondToolDelegatees,
            secondToolPolicyIpfsCids,
            true
        );

        // Call getRegisteredToolAndDelegatees
        string[] memory toolIpfsCidsForQuery = new string[](1);
        toolIpfsCidsForQuery[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet.ToolInfoWithDelegateesAndPolicies[] memory toolInfo = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndDelegatees(TEST_PKP_TOKEN_ID, toolIpfsCidsForQuery);

        // Verify number of tools
        // Verify tool info
        assertEq(toolInfo.length, 1, "Wrong number of tools");
        assertEq(toolInfo[0].toolIpfsCid, TEST_TOOL_CID, "Wrong tool CID");
        assertTrue(toolInfo[0].toolEnabled, "Tool should be enabled");
        assertEq(toolInfo[0].delegatees.length, 1, "Wrong number of delegatees for tool");
        assertEq(toolInfo[0].delegatees[0], TEST_DELEGATEE, "Wrong delegatee for tool");
        assertEq(toolInfo[0].delegateesPolicyIpfsCids[0], TEST_POLICY_CID, "Wrong policy CID for tool");
        assertTrue(toolInfo[0].delegateesPolicyEnabled[0], "Tool policy should be enabled");

        vm.stopPrank();
    }

    /// @notice Test getting specific registered tools for a PKP token
    function test_getRegisteredTools() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;

        // Register the tools
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Retrieve the registered tools
        PKPToolRegistryToolFacet.ToolInfo[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify the retrieved tools
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(registeredTools[0].toolIpfsCid, TEST_TOOL_CID, "Wrong first tool CID");
        assertTrue(registeredTools[0].toolEnabled, "First tool should be enabled");
        assertEq(registeredTools[1].toolIpfsCid, TEST_TOOL_CID_2, "Wrong second tool CID");
        assertTrue(registeredTools[1].toolEnabled, "Second tool should be enabled");

        vm.stopPrank();
    }
}
