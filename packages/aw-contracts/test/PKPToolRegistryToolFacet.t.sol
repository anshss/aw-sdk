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
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 1, "Wrong number of registered tools");
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong tool CID registered");

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
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong first tool CID registered");
        assertEq(registeredTools[1], TEST_TOOL_CID_2, "Wrong second tool CID registered");

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
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID);
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
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID);
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
}
