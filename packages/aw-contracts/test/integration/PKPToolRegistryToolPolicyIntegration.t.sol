// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryBlanketPolicyFacet.sol";
import "../../src/libraries/PKPToolRegistryErrors.sol";
import "../mocks/MockPKPNFT.sol";

contract PKPToolRegistryToolPolicyIntegrationTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    address nonOwner;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Test data
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    string constant TEST_TOOL_CID = "QmTEST";
    string constant TEST_TOOL_CID_2 = "QmTEST2";
    string constant TEST_POLICY_CID = "QmPOLICY";
    string constant TEST_POLICY_CID_2 = "QmPOLICY2";

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

    /// @notice Test getting registered tools and their policies
    function test_getRegisteredToolsAndPolicies() public {
        vm.startPrank(deployer);

        // Register multiple tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID_2;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            policyIpfsCids,
            true
        );

        // Get registered tools and policies
        (
            string[] memory registeredTools,
            string[][] memory delegateePolicyCids,
            address[] memory delegatees,
            string[] memory blanketPolicyCids
        ) = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndPolicies(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(blanketPolicyCids.length, 2, "Wrong number of blanket policies");
        assertEq(delegatees.length, 0, "Should have no delegatees");
        assertEq(delegateePolicyCids.length, 2, "Wrong number of delegatee policy arrays");
        assertEq(delegateePolicyCids[0].length, 0, "First tool should have no delegatee policies");
        assertEq(delegateePolicyCids[1].length, 0, "Second tool should have no delegatee policies");
        
        // Tools should be returned in registration order
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong first tool");
        assertEq(registeredTools[1], TEST_TOOL_CID_2, "Wrong second tool");
        
        // First tool should have blanket policy, second should have empty policy
        assertEq(blanketPolicyCids[0], TEST_POLICY_CID, "Wrong policy for first tool");
        assertEq(blanketPolicyCids[1], "", "Second tool should have empty policy");

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

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            policyIpfsCids,
            true
        );

        // Get tools with policies
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy,
            bool[] memory hasBlanketPolicy
        ) = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithPolicy.length, 1, "Wrong number of tools with policy");
        assertEq(delegateesWithPolicy.length, 1, "Wrong number of delegatee arrays");
        assertEq(hasBlanketPolicy.length, 1, "Wrong number of blanket policy flags");
        assertEq(toolsWithPolicy[0], TEST_TOOL_CID, "Wrong tool");
        assertEq(delegateesWithPolicy[0].length, 0, "Should have no delegatees");
        assertTrue(hasBlanketPolicy[0], "Should have blanket policy");

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

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryBlanketPolicyFacet(address(diamond)).setBlanketToolPolicies(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
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
} 