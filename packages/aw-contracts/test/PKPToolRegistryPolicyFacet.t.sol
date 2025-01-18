// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import "../src/libraries/PKPToolRegistryPolicyEvents.sol";
import "./mocks/MockPKPNFT.sol";

contract PKPToolRegistryPolicyFacetTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    address nonOwner;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Test data
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    uint256 constant TEST_PKP_TOKEN_ID_2 = 2;
    address constant TEST_DELEGATEE = address(0x1234);
    address constant TEST_DELEGATEE_2 = address(0x5678);
    string constant TEST_TOOL_CID = "QmTEST";
    string constant TEST_POLICY_CID = "QmPOLICY";
    string constant TEST_POLICY_CID_2 = "QmPOLICY2";

    // Events to test
    event ToolPoliciesSet(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees, string[] policyIpfsCids, bool enablePolicies);
    event ToolPoliciesRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event PoliciesEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event PoliciesDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);

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
        mockPkpNft.setOwner(TEST_PKP_TOKEN_ID_2, deployer);

        // Register a tool for testing
        vm.startPrank(deployer);
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);

        // Add a delegatee for testing
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);
        vm.stopPrank();
    }

    /// @notice Test setting a single tool policy for a delegatee
    function test_setToolPolicy() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        // Expect the ToolPoliciesSet event
        vm.expectEmit(true, false, false, true);
        emit ToolPoliciesSet(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees, policyIpfsCids, true);

        // Set the policy
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Verify policy was set
        (string memory policyCid, bool isDelegateePolicySet) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid, TEST_POLICY_CID, "Wrong policy CID");
        assertTrue(isDelegateePolicySet, "Policy should be set");

        vm.stopPrank();
    }

    /// @notice Test setting multiple tool policies for different delegatees
    function test_setMultipleToolPolicies() public {
        vm.startPrank(deployer);

        // Add second delegatee
        address[] memory newDelegatees = new address[](1);
        newDelegatees[0] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, newDelegatees);

        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        // Expect the ToolPoliciesSet event
        vm.expectEmit(true, false, false, true);
        emit ToolPoliciesSet(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees, policyIpfsCids, true);

        // Set the policies
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Verify policies were set
        (string memory policyCid1, bool isDelegateePolicySet1) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid1, TEST_POLICY_CID, "Wrong policy CID for first delegatee");
        assertTrue(isDelegateePolicySet1, "Policy should be set for first delegatee");

        (string memory policyCid2, bool isDelegateePolicySet2) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE_2
        );
        assertEq(policyCid2, TEST_POLICY_CID_2, "Wrong policy CID for second delegatee");
        assertTrue(isDelegateePolicySet2, "Policy should be set for second delegatee");

        vm.stopPrank();
    }

    /// @notice Test removing a tool policy
    function test_removeToolPolicy() public {
        vm.startPrank(deployer);

        // First set a policy
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Expect the ToolPoliciesRemoved event
        vm.expectEmit(true, false, false, true);
        emit ToolPoliciesRemoved(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Remove the policy
        PKPToolRegistryPolicyFacet(address(diamond)).removeCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policy was removed
        (string memory policyCid, bool isDelegateePolicySet) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid, "", "Policy CID should be empty");
        assertFalse(isDelegateePolicySet, "Policy should not be set");

        vm.stopPrank();
    }

    /// @notice Test enabling and disabling policies
    function test_enableDisablePolicy() public {
        vm.startPrank(deployer);

        // First set a policy (disabled)
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            false
        );

        // Expect the PoliciesEnabled event
        vm.expectEmit(true, false, false, true);
        emit PoliciesEnabled(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Enable the policy
        PKPToolRegistryPolicyFacet(address(diamond)).enableCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policy is enabled
        (string memory policyCid, bool isDelegateePolicySet) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid, TEST_POLICY_CID, "Wrong policy CID");
        assertTrue(isDelegateePolicySet, "Policy should be enabled");

        // Expect the PoliciesDisabled event
        vm.expectEmit(true, false, false, true);
        emit PoliciesDisabled(TEST_PKP_TOKEN_ID, toolIpfsCids, delegatees);

        // Disable the policy
        PKPToolRegistryPolicyFacet(address(diamond)).disableCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees
        );

        // Verify policy is disabled
        (policyCid, isDelegateePolicySet) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid, "", "Policy CID should be empty when disabled");
        assertFalse(isDelegateePolicySet, "Policy should be disabled");

        vm.stopPrank();
    }

    /// @notice Test error cases for setting policies
    function test_errorCases() public {
        vm.startPrank(deployer);

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = TEST_POLICY_CID;

        // Test non-owner cannot set policies
        vm.stopPrank();
        vm.startPrank(nonOwner);
        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );
        vm.stopPrank();
        vm.startPrank(deployer);

        // Test cannot set policy for zero address delegatee
        delegatees[0] = address(0);
        vm.expectRevert(PKPToolRegistryErrors.InvalidDelegatee.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Test cannot set policy with empty IPFS CID
        delegatees[0] = TEST_DELEGATEE;
        toolIpfsCids[0] = "";
        vm.expectRevert(PKPToolRegistryErrors.EmptyIPFSCID.selector);
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Test cannot set policy for non-existent tool
        toolIpfsCids[0] = "QmNONEXISTENT";
        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolNotFound.selector, toolIpfsCids[0]));
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        vm.stopPrank();
    }

    /// @notice Test getting tool policies
    function test_getToolPolicies() public {
        vm.startPrank(deployer);

        // Add second delegatee
        address[] memory newDelegatees = new address[](1);
        newDelegatees[0] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, newDelegatees);

        // Set policies for both delegatees
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = TEST_TOOL_CID;
        toolIpfsCids[1] = TEST_TOOL_CID;
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = TEST_POLICY_CID;
        policyIpfsCids[1] = TEST_POLICY_CID_2;

        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );

        // Get policies for both delegatees
        (string memory policyCid1, bool isDelegateePolicySet1) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(policyCid1, TEST_POLICY_CID, "Wrong policy CID for first delegatee");
        assertTrue(isDelegateePolicySet1, "Policy should be set for first delegatee");

        (string memory policyCid2, bool isDelegateePolicySet2) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE_2
        );
        assertEq(policyCid2, TEST_POLICY_CID_2, "Wrong policy CID for second delegatee");
        assertTrue(isDelegateePolicySet2, "Policy should be set for second delegatee");

        // Also verify using getCustomToolPolicyForDelegatee
        string memory customPolicyCid1 = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE
        );
        assertEq(customPolicyCid1, TEST_POLICY_CID, "Wrong custom policy CID for first delegatee");

        string memory customPolicyCid2 = PKPToolRegistryPolicyFacet(address(diamond)).getCustomToolPolicyForDelegatee(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            TEST_DELEGATEE_2
        );
        assertEq(customPolicyCid2, TEST_POLICY_CID_2, "Wrong custom policy CID for second delegatee");

        vm.stopPrank();
    }
} 