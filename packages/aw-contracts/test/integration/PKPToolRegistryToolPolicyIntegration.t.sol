// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryDelegateeFacet.sol";
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
    address constant TEST_DELEGATEE = address(0x1234);
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

        // Add delegatee
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
            policyIpfsCids,
            true
        );

        // Get registered tools and policies
        (
            string[] memory registeredTools,
            string[][] memory delegateePolicyCids,
            address[] memory delegatees
        ) = PKPToolRegistryToolFacet(address(diamond)).getRegisteredToolsAndPolicies(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(registeredTools.length, 2, "Wrong number of registered tools");
        assertEq(delegatees.length, 1, "Should have one delegatee");
        assertEq(delegateePolicyCids.length, 2, "Wrong number of delegatee policy arrays");
        assertEq(delegateePolicyCids[0].length, 1, "First tool should have one delegatee policy");
        assertEq(delegateePolicyCids[1].length, 0, "Second tool should have no delegatee policies");
        
        // Tools should be returned in registration order
        assertEq(registeredTools[0], TEST_TOOL_CID, "Wrong first tool");
        assertEq(registeredTools[1], TEST_TOOL_CID_2, "Wrong second tool");
        
        // First tool should have delegatee policy, second should have no policy
        assertEq(delegateePolicyCids[0][0], TEST_POLICY_CID, "Wrong policy for first tool");
        assertEq(delegatees[0], TEST_DELEGATEE, "Wrong delegatee");

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
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
            policyIpfsCids,
            true
        );

        // Get tools with policies
        (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy
        ) = PKPToolRegistryToolFacet(address(diamond))
            .getToolsWithPolicy(TEST_PKP_TOKEN_ID);

        // Verify results
        assertEq(toolsWithPolicy.length, 1, "Wrong number of tools with policy");
        assertEq(delegateesWithPolicy.length, 1, "Wrong number of delegatee arrays");
        assertEq(toolsWithPolicy[0], TEST_TOOL_CID, "Wrong tool");
        assertEq(delegateesWithPolicy[0].length, 1, "Should have one delegatee");
        assertEq(delegateesWithPolicy[0][0], TEST_DELEGATEE, "Wrong delegatee");

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
        address[] memory delegateesToAdd = new address[](1);
        delegateesToAdd[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegateesToAdd);

        // Set policy for first tool only
        string[] memory toolsForPolicy = new string[](1);
        toolsForPolicy[0] = TEST_TOOL_CID;
        address[] memory delegateesForPolicy = new address[](1);
        delegateesForPolicy[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolsForPolicy,
            delegateesForPolicy,
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