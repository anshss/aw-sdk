// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryBlanketPolicyFacet.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import "../src/libraries/PKPToolRegistryToolEvents.sol";
import "./mocks/MockPKPNFT.sol";

contract PKPToolRegistryToolFacetTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    address nonOwner;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Test data
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    string constant TEST_TOOL_CID = "test-tool-cid";
    string constant TEST_TOOL_CID_2 = "test-tool-cid-2";

    // Events to test
    event ToolsRegistered(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);

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
    }

    /// @notice Test getting PKP NFT contract address
    function test_getPKPNFTContract() public {
        address pkpNftContract = PKPToolRegistryToolFacet(address(diamond)).getPKPNFTContract();
        assertEq(pkpNftContract, address(mockPkpNft), "Wrong PKP NFT contract address");
    }

    /// @notice Test registering a single tool
    function test_registerSingleTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Expect the ToolsRegistered event
        vm.expectEmit(true, false, false, true);
        emit ToolsRegistered(TEST_PKP_TOKEN_ID, toolIpfsCids);

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
        vm.expectEmit(true, false, false, true);
        emit ToolsRegistered(TEST_PKP_TOKEN_ID, toolIpfsCids);

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

    /// @notice Test registering duplicate tool should not duplicate the registration
    function test_registerDuplicateTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Register first time
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Register same tool again - should succeed but not duplicate
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, false);

        // Verify tool is still registered once and maintains original enabled state
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(TEST_PKP_TOKEN_ID);
        assertEq(registeredTools.length, 1, "Should only be registered once");
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong tool CID registered");

        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertTrue(isRegistered, "Tool should still be registered");
        assertTrue(isEnabled, "Tool should maintain original enabled state");

        vm.stopPrank();
    }

    /// @notice Test registering with empty IPFS CID should revert
    function test_revert_registerEmptyIPFSCID() public {
        vm.startPrank(deployer);

        // Test empty CID in array
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Test empty CID in middle of array
        string[] memory multipleTools = new string[](3);
        multipleTools[0] = TEST_TOOL_CID;
        multipleTools[1] = ""; // Empty CID
        multipleTools[2] = TEST_TOOL_CID_2;

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, multipleTools, true);

        vm.stopPrank();
    }

    /// @notice Test non-owner registration attempt should revert
    function test_revert_registerNonOwner() public {
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
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
        vm.expectEmit(true, false, false, true);
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
        vm.expectEmit(true, false, false, true);
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

    /// @notice Test removing non-existent tool should succeed silently
    function test_removeNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Verify tool doesn't exist initially
        (bool isRegisteredBefore, bool isEnabledBefore) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredBefore, "Tool should not exist initially");
        assertFalse(isEnabledBefore, "Tool should not be enabled initially");

        // Remove non-existent tool - should succeed silently
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify state hasn't changed
        (bool isRegisteredAfter, bool isEnabledAfter) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredAfter, "Tool should still not exist");
        assertFalse(isEnabledAfter, "Tool should still not be enabled");

        vm.stopPrank();
    }

    /// @notice Test removing with empty IPFS CID should revert
    function test_revert_removeEmptyIPFSCID() public {
        vm.startPrank(deployer);

        // Test empty CID in array
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Test empty CID in middle of array
        string[] memory multipleTools = new string[](3);
        multipleTools[0] = TEST_TOOL_CID;
        multipleTools[1] = ""; // Empty CID
        multipleTools[2] = TEST_TOOL_CID_2;

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, multipleTools);

        vm.stopPrank();
    }

    /// @notice Test non-owner removal attempt should revert
    function test_revert_removeNonOwner() public {
        vm.startPrank(nonOwner);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
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
        vm.expectEmit(true, false, false, true);
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
        vm.expectEmit(true, false, false, true);
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

    /// @notice Test enabling non-existent tool should succeed silently
    function test_enableNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Verify tool doesn't exist initially
        (bool isRegisteredBefore, bool isEnabledBefore) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredBefore, "Tool should not exist initially");
        assertFalse(isEnabledBefore, "Tool should not be enabled initially");

        // Enable non-existent tool - should succeed silently
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify state hasn't changed
        (bool isRegisteredAfter, bool isEnabledAfter) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredAfter, "Tool should still not exist");
        assertFalse(isEnabledAfter, "Tool should still not be enabled");

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
        vm.expectEmit(true, false, false, true);
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
        vm.expectEmit(true, false, false, true);
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

    /// @notice Test disabling non-existent tool should succeed silently
    function test_disableNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Verify tool doesn't exist initially
        (bool isRegisteredBefore, bool isEnabledBefore) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredBefore, "Tool should not exist initially");
        assertFalse(isEnabledBefore, "Tool should not be enabled initially");

        // Disable non-existent tool - should succeed silently
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Verify state hasn't changed
        (bool isRegisteredAfter, bool isEnabledAfter) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(TEST_PKP_TOKEN_ID, TEST_TOOL_CID);
        assertFalse(isRegisteredAfter, "Tool should still not exist");
        assertFalse(isEnabledAfter, "Tool should still not be enabled");

        vm.stopPrank();
    }

    /// @notice Test that blanket policy indices align correctly with tool indices in getRegisteredToolsAndPolicies
    function test_getRegisteredToolsAndPoliciesIndexAlignment() public {
        vm.startPrank(deployer);

        // Register first tool and set blanket policy (enabled)
        string[] memory tool1 = new string[](1);
        tool1[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool1, true);

        string[] memory policy1 = new string[](1);
        policy1[0] = "policy-1";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool1, policy1, true);

        // Register second tool and set blanket policy (disabled)
        string[] memory tool2 = new string[](1);
        tool2[0] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool2, true);

        string[] memory policy2 = new string[](1);
        policy2[0] = "policy-2";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool2, policy2, false);

        // Add a delegatee with enabled and disabled policies
        address delegatee = makeAddr("delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;

        // Add delegatee to PKP
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        string[] memory delegateePolicies = new string[](1);

        // Set enabled policy for first tool
        delegateePolicies[0] = "delegatee-policy-1";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            tool1,
            delegatees,
            delegateePolicies,
            true
        );

        // Set disabled policy for second tool
        delegateePolicies[0] = "delegatee-policy-2";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            tool2,
            delegatees,
            delegateePolicies,
            false
        );

        // Get all tools and policies
        (
            string[] memory toolIpfsCids,
            string[][] memory delegateePolicyCids,
            address[] memory allDelegatees,
            string[] memory blanketPolicyCids
        ) = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndPolicies(TEST_PKP_TOKEN_ID);

        // Verify lengths match
        assertEq(toolIpfsCids.length, 2, "Should have 2 tools registered");
        assertEq(blanketPolicyCids.length, 2, "Should have 2 blanket policy slots");
        assertEq(allDelegatees.length, 1, "Should have 1 delegatee");
        assertEq(delegateePolicyCids.length, 2, "Should have 2 delegatee policy arrays");
        assertEq(delegateePolicyCids[0].length, 1, "First tool should have 1 delegatee policy");
        assertEq(delegateePolicyCids[1].length, 1, "Second tool should have 1 delegatee policy");

        // Verify first tool has blanket policy and enabled delegatee policy
        assertEq(toolIpfsCids[0], TEST_TOOL_CID, "First tool should be TEST_TOOL_CID");
        assertEq(blanketPolicyCids[0], "policy-1", "First tool should show enabled blanket policy");
        assertEq(delegateePolicyCids[0][0], "delegatee-policy-1", "First tool should show enabled delegatee policy");

        // Verify second tool's disabled policies are visible
        assertEq(toolIpfsCids[1], TEST_TOOL_CID_2, "Second tool should be TEST_TOOL_CID_2");
        assertEq(blanketPolicyCids[1], "policy-2", "Second tool's disabled blanket policy should be visible");
        assertEq(delegateePolicyCids[1][0], "delegatee-policy-2", "Second tool's disabled delegatee policy should be visible");

        // Verify getToolsWithPolicy shows both tools with policies
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy,
            bool[] memory hasBlanketPolicy
        ) = PKPToolRegistryToolFacet(address(diamond)).getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify both tools are included
        assertEq(toolsWithPolicy.length, 2, "Should show both tools with policies");
        assertEq(toolsWithPolicy[0], TEST_TOOL_CID, "First tool should be TEST_TOOL_CID");
        assertEq(toolsWithPolicy[1], TEST_TOOL_CID_2, "Second tool should be TEST_TOOL_CID_2");

        // Verify both are marked as having blanket policies
        assertTrue(hasBlanketPolicy[0], "First tool should be marked as having blanket policy");
        assertTrue(hasBlanketPolicy[1], "Second tool should be marked as having blanket policy");

        // Verify delegatees are included
        assertEq(delegateesWithPolicy[0].length, 1, "First tool should have 1 delegatee");
        assertEq(delegateesWithPolicy[1].length, 1, "Second tool should have 1 delegatee");
        assertEq(delegateesWithPolicy[0][0], delegatee, "First tool should have correct delegatee");
        assertEq(delegateesWithPolicy[1][0], delegatee, "Second tool should have correct delegatee");

        vm.stopPrank();
    }

    /// @notice Test that blanket policy indices align correctly with tool indices in getRegisteredToolsAndPolicies without delegatees
    function test_getRegisteredToolsAndPoliciesWithoutDelegatees() public {
        vm.startPrank(deployer);

        // Register first tool and set blanket policy (enabled)
        string[] memory tool1 = new string[](1);
        tool1[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool1, true);

        string[] memory policy1 = new string[](1);
        policy1[0] = "policy-1";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool1, policy1, true);

        // Register second tool and set blanket policy (disabled)
        string[] memory tool2 = new string[](1);
        tool2[0] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool2, true);

        string[] memory policy2 = new string[](1);
        policy2[0] = "policy-2";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool2, policy2, false);

        // Get all tools and policies
        (
            string[] memory toolIpfsCids,
            string[][] memory delegateePolicyCids,
            address[] memory allDelegatees,
            string[] memory blanketPolicyCids
        ) = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndPolicies(TEST_PKP_TOKEN_ID);

        // Verify lengths match
        assertEq(toolIpfsCids.length, 2, "Should have 2 tools registered");
        assertEq(blanketPolicyCids.length, 2, "Should have 2 blanket policy slots");
        assertEq(allDelegatees.length, 0, "Should have no delegatees");
        assertEq(delegateePolicyCids.length, 2, "Should have 2 delegatee policy arrays");
        assertEq(delegateePolicyCids[0].length, 0, "First tool should have no delegatee policies");
        assertEq(delegateePolicyCids[1].length, 0, "Second tool should have no delegatee policies");

        // Verify first tool has enabled blanket policy
        assertEq(toolIpfsCids[0], TEST_TOOL_CID, "First tool should be TEST_TOOL_CID");
        assertEq(blanketPolicyCids[0], "policy-1", "First tool should show enabled blanket policy");

        // Verify second tool's disabled policy is visible
        assertEq(toolIpfsCids[1], TEST_TOOL_CID_2, "Second tool should be TEST_TOOL_CID_2");
        assertEq(blanketPolicyCids[1], "policy-2", "Second tool's disabled blanket policy should be visible");

        // Verify getToolsWithPolicy shows both tools with policies
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy,
            bool[] memory hasBlanketPolicy
        ) = PKPToolRegistryToolFacet(address(diamond)).getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify both tools are included
        assertEq(toolsWithPolicy.length, 2, "Should show both tools with policies");
        assertEq(toolsWithPolicy[0], TEST_TOOL_CID, "First tool should be TEST_TOOL_CID");
        assertEq(toolsWithPolicy[1], TEST_TOOL_CID_2, "Second tool should be TEST_TOOL_CID_2");

        // Verify both are marked as having blanket policies
        assertTrue(hasBlanketPolicy[0], "First tool should be marked as having blanket policy");
        assertTrue(hasBlanketPolicy[1], "Second tool should be marked as having blanket policy");

        // Verify no delegatees
        assertEq(delegateesWithPolicy[0].length, 0, "First tool should have no delegatees");
        assertEq(delegateesWithPolicy[1].length, 0, "Second tool should have no delegatees");

        vm.stopPrank();
    }

    /// @notice Test getting tools without any policies
    function test_getToolsWithoutPolicy() public {
        vm.startPrank(deployer);

        // Register first tool without any policy
        string[] memory tool1 = new string[](1);
        tool1[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool1, true);

        // Register second tool with blanket policy
        string[] memory tool2 = new string[](1);
        tool2[0] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool2, true);

        string[] memory policy2 = new string[](1);
        policy2[0] = "policy-2";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool2, policy2, true);

        // Register third tool with disabled blanket policy
        string[] memory tool3 = new string[](1);
        tool3[0] = "test-tool-cid-3";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, tool3, true);

        string[] memory policy3 = new string[](1);
        policy3[0] = "policy-3";
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(TEST_PKP_TOKEN_ID, tool3, policy3, false);

        // Get tools without policy
        string[] memory toolsWithoutPolicy = PKPToolRegistryToolFacet(address(diamond)).getToolsWithoutPolicy(TEST_PKP_TOKEN_ID);

        // Should only return the first tool (no policy at all)
        assertEq(toolsWithoutPolicy.length, 1, "Should have 1 tool without policy");
        assertEq(toolsWithoutPolicy[0], TEST_TOOL_CID, "Only tool without policy should be TEST_TOOL_CID");

        // Add a delegatee policy to the first tool
        address delegatee = makeAddr("delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;

        // Add delegatee to PKP
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        string[] memory delegateePolicies = new string[](1);
        delegateePolicies[0] = "delegatee-policy-1";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            tool1,
            delegatees,
            delegateePolicies,
            true
        );

        // Get tools without policy again
        toolsWithoutPolicy = PKPToolRegistryToolFacet(address(diamond)).getToolsWithoutPolicy(TEST_PKP_TOKEN_ID);

        // Should return empty array as all tools have some form of policy (enabled or disabled)
        assertEq(toolsWithoutPolicy.length, 0, "Should have no tools without policy");

        vm.stopPrank();
    }

    /// @notice Test that registering duplicate tools doesn't include them in the event
    function test_registerDuplicateToolEvent() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;

        // Register first time
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Try to register both tools again, but only add a third new one
        string[] memory duplicateTools = new string[](3);
        duplicateTools[0] = TEST_TOOL_CID; // Already registered
        duplicateTools[1] = TEST_TOOL_CID_2; // Already registered
        duplicateTools[2] = "test-tool-cid-3"; // New tool

        // Expect event to only include the new tool
        string[] memory expectedTools = new string[](1);
        expectedTools[0] = "test-tool-cid-3";
        vm.expectEmit(true, false, false, true);
        emit ToolsRegistered(TEST_PKP_TOKEN_ID, expectedTools);

        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, duplicateTools, true);

        vm.stopPrank();
    }

    /// @notice Test that removing non-existent tools doesn't include them in the event
    function test_removeNonExistentToolEvent() public {
        vm.startPrank(deployer);

        // Register one tool
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Try to remove two tools, one that exists and one that doesn't
        string[] memory removeTools = new string[](2);
        removeTools[0] = TEST_TOOL_CID; // Exists
        removeTools[1] = TEST_TOOL_CID_2; // Doesn't exist

        // Expect event to only include the existing tool
        string[] memory expectedTools = new string[](1);
        expectedTools[0] = TEST_TOOL_CID;
        vm.expectEmit(true, false, false, true);
        emit ToolsRemoved(TEST_PKP_TOKEN_ID, expectedTools);

        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, removeTools);

        vm.stopPrank();
    }

    /// @notice Test that enabling already enabled tools doesn't include them in the event
    function test_enableAlreadyEnabledToolEvent() public {
        vm.startPrank(deployer);

        // Register two tools (enabled)
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Disable one tool
        string[] memory disableTools = new string[](1);
        disableTools[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, disableTools);

        // Try to enable both tools
        // Expect event to only include the disabled tool
        string[] memory expectedTools = new string[](1);
        expectedTools[0] = TEST_TOOL_CID;
        vm.expectEmit(true, false, false, true);
        emit ToolsEnabled(TEST_PKP_TOKEN_ID, expectedTools);

        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test that disabling already disabled tools doesn't include them in the event
    function test_disableAlreadyDisabledToolEvent() public {
        vm.startPrank(deployer);

        // Register two tools (enabled)
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Disable one tool
        string[] memory disableTools = new string[](1);
        disableTools[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, disableTools);

        // Try to disable both tools
        // Expect event to only include the enabled tool
        string[] memory expectedTools = new string[](1);
        expectedTools[0] = TEST_TOOL_CID_2;
        vm.expectEmit(true, false, false, true);
        emit ToolsDisabled(TEST_PKP_TOKEN_ID, expectedTools);

        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test that no event is emitted when no tools are modified
    function test_noEventWhenNoToolsModified() public {
        vm.startPrank(deployer);

        // Register two tools (enabled)
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Record all events before our test operations
        vm.recordLogs();

        // Try to register the same tools again - should not emit event
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Try to enable already enabled tools - should not emit event
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Disable the tools (this will emit an event, but we'll clear logs after)
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Clear logs to start fresh
        vm.recordLogs();

        // Try to disable already disabled tools - should not emit event
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Try to remove non-existent tools - should not emit event
        string[] memory nonExistentTools = new string[](1);
        nonExistentTools[0] = "non-existent-tool";
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, nonExistentTools);

        // Verify no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0, "No events should have been emitted");

        vm.stopPrank();
    }

    /// @notice Test enabling with empty IPFS CID should revert
    function test_revert_enableEmptyIPFSCID() public {
        vm.startPrank(deployer);

        // Test empty CID in array
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Test empty CID in middle of array
        string[] memory multipleTools = new string[](3);
        multipleTools[0] = TEST_TOOL_CID;
        multipleTools[1] = ""; // Empty CID
        multipleTools[2] = TEST_TOOL_CID_2;

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).enableTools(TEST_PKP_TOKEN_ID, multipleTools);

        vm.stopPrank();
    }

    /// @notice Test disabling with empty IPFS CID should revert
    function test_revert_disableEmptyIPFSCID() public {
        vm.startPrank(deployer);

        // Test empty CID in array
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        // Test empty CID in middle of array
        string[] memory multipleTools = new string[](3);
        multipleTools[0] = TEST_TOOL_CID;
        multipleTools[1] = ""; // Empty CID
        multipleTools[2] = TEST_TOOL_CID_2;

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).disableTools(TEST_PKP_TOKEN_ID, multipleTools);

        vm.stopPrank();
    }
} 