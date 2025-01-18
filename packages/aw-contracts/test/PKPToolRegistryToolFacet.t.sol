// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
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

    /// @notice Test registering with empty IPFS CID should revert
    function test_revert_registerEmptyIPFSCID() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        vm.stopPrank();
    }

    /// @notice Test registering duplicate tool should revert
    function test_revert_registerDuplicateTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        // Register first time
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Try to register same tool again
        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolAlreadyExists.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

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

    /// @notice Test removing with empty IPFS CID should revert
    function test_revert_removeEmptyIPFSCID() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = ""; // Empty CID

        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

        vm.stopPrank();
    }

    /// @notice Test removing non-existent tool should revert
    function test_revert_removeNonExistentTool() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;

        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolNotFound.selector, TEST_TOOL_CID));
        PKPToolRegistryToolFacet(address(diamond)).removeTools(TEST_PKP_TOKEN_ID, toolIpfsCids);

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
} 