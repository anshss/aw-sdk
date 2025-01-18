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
import "../src/facets/PKPToolRegistryBlanketPolicyFacet.sol";
import "../src/facets/PKPToolRegistryBlanketParameterFacet.sol";
import "../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
import "../src/libraries/PKPToolRegistryStorage.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import { LibDiamond, NotContractOwner } from "../src/diamond/libraries/LibDiamond.sol";
import "./mocks/MockPKPNFT.sol";

/// @title PKP Tool Registry Diamond Test
/// @notice Tests the Diamond implementation of PKP Tool Registry
/// @dev Tests deployment, facet installation, and upgrade functionality
contract PKPToolRegistryDiamondTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Events to test
    event DiamondCut(IDiamond.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        // Setup deployer account using default test account
        deployer = vm.addr(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // Deploy mock PKP NFT contract
        mockPkpNft = new MockPKPNFT();

        // Set environment variables for deployment
        vm.setEnv("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        
        // Deploy using the script
        deployScript = new DeployPKPToolRegistry();
        address diamondAddress = deployScript.deployToNetwork("test", address(mockPkpNft));
        diamond = PKPToolRegistry(payable(diamondAddress));

        // Set up mock PKP NFT for tests
        mockPkpNft.setOwner(1, deployer);
    }

    /// @notice Test that all facets are correctly installed
    function test_facetsAreInstalled() public {
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(address(diamond)).facets();
        
        // Should have 9 facets (DiamondCut + 8 others)
        assertEq(facets.length, 9, "Wrong number of facets");
        
        // Verify each facet has the correct number of functions
        for (uint i = 0; i < facets.length; i++) {
            bytes4[] memory selectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(facets[i].facetAddress);
            
            // Get expected number of selectors based on facet
            uint256 expectedSelectors = getExpectedSelectorCount(facets[i].facetAddress);
            assertEq(selectors.length, expectedSelectors, "Wrong number of selectors for facet");
        }
    }

    /// @notice Test that the contract supports expected interfaces
    function test_supportsInterfaces() public {
        // Test ERC165 support
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId), "Should support ERC165");
        
        // Test Diamond interfaces
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId), "Should support IDiamondCut");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId), "Should support IDiamondLoupe");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId), "Should support IERC173");
    }

    /// @notice Test ownership functionality
    function test_ownership() public {
        assertEq(IERC173(address(diamond)).owner(), deployer, "Wrong owner");
        
        // Test ownership transfer
        address newOwner = makeAddr("newOwner");
        vm.prank(deployer);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(deployer, newOwner);
        IERC173(address(diamond)).transferOwnership(newOwner);
        
        assertEq(IERC173(address(diamond)).owner(), newOwner, "Ownership not transferred");
    }

    /// @notice Test diamond cut functionality
    function test_diamondCut() public {
        // Deploy a new facet for testing upgrades
        vm.startPrank(deployer);
        PKPToolRegistryPolicyFacet newPolicyFacet = new PKPToolRegistryPolicyFacet();
        
        // Create diamond cut for upgrade
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(newPolicyFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: deployScript.getPolicyFacetSelectors()
        });
        
        // Execute upgrade
        vm.expectEmit(true, true, true, true);
        emit DiamondCut(cut, address(0), "");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        
        // Verify upgrade
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(
            PKPToolRegistryPolicyFacet.getEffectiveToolPolicyForDelegatee.selector
        );
        assertEq(facetAddress, address(newPolicyFacet), "Facet not upgraded");
        vm.stopPrank();
    }

    /// @notice Test initialization state
    function test_initialization() public {
        // Test PKP NFT contract address using the diamond's interface
        address pkpNftContract = PKPToolRegistryToolFacet(address(diamond)).getPKPNFTContract();
        assertEq(pkpNftContract, address(mockPkpNft), "PKP NFT address not set correctly");
    }

    /// @notice Test diamond cut access control
    function test_diamondCutOwnerOnly() public {
        address nonOwner = makeAddr("non-owner");
        
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: functionSelectors
        });
        
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(NotContractOwner.selector, nonOwner, deployer));
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    /// @notice Test core functionality of facets
    function test_facetFunctionality() public {
        vm.startPrank(deployer);
        
        // Test Tool Registration
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "test-tool";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        // Test tool listing
        string[] memory registeredTools = PKPToolRegistryToolFacet(address(diamond)).getRegisteredTools(1);
        assertEq(registeredTools.length, 1, "Wrong number of registered tools");
        assertEq(registeredTools[0], "test-tool", "Wrong tool ID registered");
        
        // Test delegatee management
        address delegatee = makeAddr("delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(1, delegatees);
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, delegatee), "Delegatee not added");
        
        // Test policy setting
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = "test-policy";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            1,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true // enable policies
        );
        
        (string memory policyIpfsCid, bool isDelegateeSpecific) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(
            1,
            toolIpfsCids[0],
            delegatee
        );
        assertEq(policyIpfsCid, "test-policy", "Policy not set correctly");
        assertTrue(isDelegateeSpecific, "Policy should be delegatee specific");
        
        vm.stopPrank();
    }

    /// @notice Test storage layout
    function test_storageLayout() public {
        vm.startPrank(deployer);
        
        // Register tools
        string[] memory toolIpfsCids = new string[](2);
        toolIpfsCids[0] = "test-tool-1";
        toolIpfsCids[1] = "test-tool-2";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        // Add delegatees
        address delegatee1 = makeAddr("delegatee1");
        address delegatee2 = makeAddr("delegatee2");
        address[] memory delegatees = new address[](2);
        delegatees[0] = delegatee1;
        delegatees[1] = delegatee2;
        
        // Set up token ID 2 in mock NFT
        mockPkpNft.setOwner(2, deployer);
        
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(1, delegatees);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(2, delegatees);
        
        // Set policies
        string[] memory policyIpfsCids = new string[](2);
        policyIpfsCids[0] = "policy-1";
        policyIpfsCids[1] = "policy-2";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            1,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true // enable policies
        );
        
        // Register tools again for second PKP
        PKPToolRegistryToolFacet(address(diamond)).registerTools(2, toolIpfsCids, true);

        // Verify all storage values are maintained
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[0]);
        assertTrue(isRegistered && isEnabled, "Tool 1 storage corrupted");
        (isRegistered, isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[1]);
        assertTrue(isRegistered && isEnabled, "Tool 2 storage corrupted");
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, delegatee1), "Delegatee 1 storage corrupted");
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(2, delegatee2), "Delegatee 2 storage corrupted");
        
        (string memory policy1, bool isDelegateeSpecific1) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(1, toolIpfsCids[0], delegatee1);
        assertEq(policy1, "policy-1", "Policy 1 storage corrupted");
        assertTrue(isDelegateeSpecific1, "Policy 1 should be delegatee specific");
        
        (string memory policy2, bool isDelegateeSpecific2) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(1, toolIpfsCids[1], delegatee2);
        assertEq(policy2, "policy-2", "Policy 2 storage corrupted");
        assertTrue(isDelegateeSpecific2, "Policy 2 should be delegatee specific");
        
        vm.stopPrank();
    }

    /// @notice Test complete upgrade scenario
    function test_completeUpgrade() public {
        vm.startPrank(deployer);
        
        // Set up initial state
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "upgrade-test-tool";
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        address delegatee = makeAddr("upgrade-test-delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(1, delegatees);
        
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = "upgrade-test-policy";
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            1,
            toolIpfsCids,
            delegatees,
            policyIpfsCids,
            true // enable policies
        );
        
        // Deploy new facet version
        PKPToolRegistryPolicyFacet newPolicyFacet = new PKPToolRegistryPolicyFacet();
        
        // Create and execute upgrade
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(newPolicyFacet),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: deployScript.getPolicyFacetSelectors()
        });
        
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        
        // Verify state is preserved
        (bool isRegistered, bool isEnabled) = PKPToolRegistryToolFacet(address(diamond)).isToolRegistered(1, toolIpfsCids[0]);
        assertTrue(isRegistered && isEnabled, "Tool registration not preserved");
        assertTrue(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, delegatee), "Delegatee not preserved");
        
        (string memory policy, bool isDelegateeSpecific) = PKPToolRegistryPolicyFacet(address(diamond)).getEffectiveToolPolicyForDelegatee(1, toolIpfsCids[0], delegatee);
        assertEq(policy, "upgrade-test-policy", "Policy not preserved");
        assertTrue(isDelegateeSpecific, "Policy should be delegatee specific");
        
        vm.stopPrank();
    }

    /// @notice Test error cases
    function test_errorCases() public {
        vm.startPrank(deployer);
        
        // Test duplicate tool registration
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = "error-test-tool";
        
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolAlreadyExists.selector, "error-test-tool"));
        PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids, true);
        
        // Test policy setting for non-existent tool
        string[] memory nonExistentTools = new string[](1);
        nonExistentTools[0] = "non-existent-tool";
        string[] memory policyIpfsCids = new string[](1);
        policyIpfsCids[0] = "error-test-policy";
        
        address delegatee = makeAddr("error-test-delegatee");
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        
        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolNotFound.selector, "non-existent-tool"));
        PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
            1,
            nonExistentTools,
            delegatees,
            policyIpfsCids,
            true // enable policies
        );
        
        // Test removing non-existent delegatee
        // First verify the delegatee doesn't exist
        address nonExistentDelegateePure = makeAddr("non-existent-delegatee-pure");
        assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should not exist");
        
        // Now try to remove it - this should succeed silently
        address[] memory nonExistentDelegateesArray = new address[](1);
        nonExistentDelegateesArray[0] = nonExistentDelegateePure;
        
        // Since the delegatee doesn't exist, removing it should have no effect
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(1, nonExistentDelegateesArray);
        
        // Verify it still doesn't exist
        assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should still not exist");
        
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
        if (hash == keccak256(type(PKPToolRegistryBlanketPolicyFacet).runtimeCode)) return deployScript.getBlanketPolicyFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryBlanketParameterFacet).runtimeCode)) return deployScript.getBlanketParameterFacetSelectors().length;
        if (hash == keccak256(type(PKPToolRegistryPolicyParameterFacet).runtimeCode)) return deployScript.getPolicyParameterFacetSelectors().length;
        
        return 0;
    }
} 