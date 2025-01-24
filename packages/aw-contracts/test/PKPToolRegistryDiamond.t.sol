// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/diamond/interfaces/IDiamondLoupe.sol";
import "../src/diamond/interfaces/IDiamondCut.sol";
import "../src/diamond/interfaces/IERC165.sol";
import "../src/diamond/interfaces/IERC173.sol";
import "../src/diamond/interfaces/IDiamond.sol";
import "../src/diamond/facets/DiamondCutFacet.sol";
import "../src/diamond/facets/DiamondLoupeFacet.sol";
import "../src/diamond/facets/OwnershipFacet.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
import "../src/libraries/PKPToolRegistryStorage.sol";
import { LibDiamond, NotContractOwner } from "../src/diamond/libraries/LibDiamond.sol";
import { LibPKPToolRegistryToolFacet } from "../src/facets/PKPToolRegistryToolFacet.sol";
import { LibPKPToolRegistryBase } from "../src/abstract/PKPToolRegistryBase.sol";
import "./mocks/MockPKPNFT.sol";
import "./helpers/TestHelper.sol";

/// @title PKP Tool Registry Diamond Test
/// @notice Tests the Diamond implementation of PKP Tool Registry
/// @dev Tests deployment, facet installation, and upgrade functionality
contract PKPToolRegistryDiamondTest is Test, TestHelper {
    // Events to test
    event DiamondCut(IDiamond.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public override {
        super.setUp();
    }

    //////////////////////////////////////////////////////////////
    // Diamond Core Tests
    //////////////////////////////////////////////////////////////

    /// @notice Test that all facets are correctly installed and have the expected number of functions
    function test_facetsAreInstalled() public {
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(address(diamond)).facets();
        
        // Should have 7 facets (DiamondCut + 6 others)
        assertEq(facets.length, 7, "Wrong number of facets");
        
        // Verify each facet has the correct number of functions
        for (uint i = 0; i < facets.length; i++) {
            bytes4[] memory selectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(facets[i].facetAddress);
            uint256 expectedSelectors = getExpectedSelectorCount(facets[i].facetAddress);
            assertEq(selectors.length, expectedSelectors, string.concat(
                "Wrong number of selectors for facet at index ", vm.toString(i)
            ));
        }
    }

    /// @notice Test that the contract supports all required EIP-2535 interfaces
    function test_supportsInterfaces() public {
        // Test ERC165 support (required by EIP-2535)
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId), "Should support ERC165");
        
        // Test Diamond interfaces (required by EIP-2535)
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId), "Should support IDiamondCut");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId), "Should support IDiamondLoupe");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId), "Should support IERC173");
    }

    /// @notice Test diamond cut functionality including access control and events
    function test_diamondCut() public {
        vm.startPrank(deployer);
        
        // Deploy a new facet for testing upgrades
        PKPToolRegistryPolicyFacet newPolicyFacet = new PKPToolRegistryPolicyFacet();
        
        // Create diamond cut for upgrade
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(newPolicyFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: deployScript.getPolicyFacetSelectors()
        });
        
        // Test event emission
        vm.expectEmit(true, true, true, true);
        emit DiamondCut(cut, address(0), "");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        
        // Verify upgrade by checking function selector mapping
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(
            PKPToolRegistryPolicyFacet.getToolPoliciesForDelegatees.selector
        );
        assertEq(facetAddress, address(newPolicyFacet), "Facet not upgraded");

        vm.stopPrank();
    }

    /// @notice Test diamond cut access control
    function test_diamondCutOwnerOnly() public {
        address nonOwner = makeAddr("non-owner");
        
        // Create a cut that would remove the diamondCut function
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: functionSelectors
        });
        
        // Test that non-owner cannot perform diamond cut
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(NotContractOwner.selector, nonOwner, deployer));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////
    // Diamond Storage Tests
    //////////////////////////////////////////////////////////////

    /// @notice Test that storage layout is preserved during upgrades
    function test_storageLayout() public {
        vm.startPrank(deployer);
        
        // 1. Set up initial state with multiple PKPs, tools, and policies
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = "test-tool-1";
        toolIpfsCids[1] = "test-tool-2";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        address delegatee1 = makeAddr("delegatee1");
        address delegatee2 = makeAddr("delegatee2");
        address[] memory delegatees = new address[](2);
        delegatees[0] = delegatee1;
        delegatees[1] = delegatee2;
        
        // Set up second PKP
        mockPkpNft.setOwner(2, deployer);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(1, delegatees);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(2, delegatees);
        
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = "policy-1";
        policyIpfsCids[1] = "policy-2";
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            1,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );
        
        // Register tools for second PKP
        PKPToolRegistryToolFacet(address(diamond)).registerTools(2, toolIpfsCids, true);

        // 2. Deploy new facet version
        PKPToolRegistryPolicyFacet newPolicyFacet = new PKPToolRegistryPolicyFacet();
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(newPolicyFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: deployScript.getPolicyFacetSelectors()
        });
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // 3. Verify all storage values are maintained after upgrade
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[0]);
        assertTrue(isRegistered && isEnabled, "Tool 1 storage corrupted");
        (isRegistered, isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[1]);
        assertTrue(isRegistered && isEnabled, "Tool 2 storage corrupted");
        
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, delegatee1), "Delegatee 1 storage corrupted");
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(2, delegatee2), "Delegatee 2 storage corrupted");
        
        string[] memory queryTools = new string[](2);
        queryTools[0] = toolIpfsCids[0];
        queryTools[1] = toolIpfsCids[1];
        address[] memory queryDelegatees = new address[](2);
        queryDelegatees[0] = delegatee1;
        queryDelegatees[1] = delegatee2;
        
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "policy-1", "Policy 1 storage corrupted");
        assertTrue(policies[0].enabled, "Policy 1 should be enabled");
        assertEq(policies[0].delegatee, delegatee1, "Wrong delegatee for policy 1");
        assertEq(policies[1].policyIpfsCid, "policy-2", "Policy 2 storage corrupted");
        assertTrue(policies[1].enabled, "Policy 2 should be enabled");
        assertEq(policies[1].delegatee, delegatee2, "Wrong delegatee for policy 2");
        
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////
    // Diamond Upgrade Tests
    //////////////////////////////////////////////////////////////

    /// @notice Test complete upgrade scenario including state preservation
    function test_completeUpgrade() public {
        vm.startPrank(deployer);
        
        // 1. Set up complex initial state
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "upgrade-test-tool";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        address delegatee = makeAddr("upgrade-test-delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(1, delegatees);
        
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = "upgrade-test-policy";
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            1,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true
        );
        
        // 2. Deploy and upgrade to new facet version
        PKPToolRegistryPolicyFacet newPolicyFacet = new PKPToolRegistryPolicyFacet();
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(newPolicyFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: deployScript.getPolicyFacetSelectors()
        });
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        
        // 3. Verify state preservation
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[0]);
        assertTrue(isRegistered && isEnabled, "Tool registration not preserved");
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, delegatee), "Delegatee not preserved");
        
        string[] memory queryTools = new string[](1);
        queryTools[0] = toolIpfsCids[0];
        address[] memory queryDelegatees = new address[](1);
        queryDelegatees[0] = delegatee;
        
        PKPToolRegistryPolicyFacet.ToolPolicy[] memory policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "upgrade-test-policy", "Policy not preserved");
        assertTrue(policies[0].enabled, "Policy should be delegatee specific");
        assertEq(policies[0].delegatee, delegatee, "Wrong delegatee for policy");
        
        // 4. Test new functionality after upgrade
        policies = PKPToolRegistryPolicyFacet(address(diamond)).getToolPoliciesForDelegatees(
            TEST_PKP_TOKEN_ID,
            queryTools,
            queryDelegatees
        );
        assertEq(policies[0].policyIpfsCid, "upgrade-test-policy", "Policy not set correctly after upgrade");
        assertTrue(policies[0].enabled, "Policy not enabled after upgrade");
        assertEq(policies[0].delegatee, delegatee, "Wrong delegatee for policy after upgrade");
        
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////////////
    // Diamond Error Cases
    //////////////////////////////////////////////////////////////

    /// @notice Test error cases for diamond operations
    function test_errorCases() public {
        vm.startPrank(deployer);
        
        // Test empty inputs
        string[] memory emptyToolIpfsCids = new string[](1);
        emptyToolIpfsCids[0] = "";
        vm.expectRevert(LibPKPToolRegistryToolFacet.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, emptyToolIpfsCids, true);
        
        string[] memory noTools = new string[](0);
        vm.expectRevert(LibPKPToolRegistryToolFacet.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, noTools, true);

        // Test non-existent resources
        string[] memory nonExistentTools = new string[](1);
        nonExistentTools[0] = "non-existent-tool";
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = "error-test-policy";
        
        address delegatee = makeAddr("error-test-delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        
        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryToolFacet.ToolNotFound.selector, "non-existent-tool"));
        PKPToolRegistryPolicyFacet(address(diamond)).setToolPoliciesForDelegatees(
            1,
            nonExistentTools,
            delegatees,
            policyIpfsCids,
            true
        );

        // Test invalid operations
        vm.expectRevert(LibPKPToolRegistryToolFacet.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(1, noTools);

        vm.expectRevert(LibPKPToolRegistryToolFacet.EmptyIPFSCID.selector);
        PKPToolRegistryToolFacet(address(diamond)).removeTools(1, emptyToolIpfsCids);
        
        // Test non-existent delegatee operations
        address nonExistentDelegateePure = makeAddr("non-existent-delegatee-pure");
        assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should not exist");
        
        address[] memory nonExistentDelegateesArray = new address[](1);
        nonExistentDelegateesArray[0] = nonExistentDelegateePure;
        vm.expectRevert(abi.encodeWithSelector(LibPKPToolRegistryDelegateeFacet.DelegateeNotFound.selector, 1, nonExistentDelegateePure));
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(1, nonExistentDelegateesArray);
        assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should still not exist");

        vm.stopPrank();

        // Test unauthorized access
        address nonOwner = makeAddr("non-owner");
        vm.startPrank(nonOwner);
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "unauthorized-test-tool";
        vm.expectRevert(LibPKPToolRegistryBase.NotPKPOwner.selector);
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        vm.stopPrank();
    }

    /// @notice Helper function to get expected selector count for a facet
    function getExpectedSelectorCount(address facetAddress) internal view returns (uint256) {
        bytes memory facetCode = facetAddress.code;
        bytes32 hash = keccak256(facetCode);
        
        // Compare code hash to determine facet type
        if (hash == keccak256(type(DiamondCutFacet).runtimeCode)) return 1;
        if (hash == keccak256(type(DiamondLoupeFacet).runtimeCode)) return deployScript.getDiamondLoupeFacetSelectors().length;
        if (hash == keccak256(type(OwnershipFacet).runtimeCode)) return deployScript.getOwnershipFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryPolicyFacet).runtimeCode)) return deployScript.getPolicyFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryToolFacet).runtimeCode)) return deployScript.getToolFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryDelegateeFacet).runtimeCode)) return deployScript.getDelegateeFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryPolicyParameterFacet).runtimeCode)) return deployScript.getPolicyParameterFacetSelectors().length;
        
        return 0;
    }
}
