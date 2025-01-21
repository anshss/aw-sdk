// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PKPToolRegistry.sol";
import "../src/diamond/facets/DiamondCutFacet.sol";
import "../src/diamond/facets/DiamondLoupeFacet.sol";
import "../src/diamond/facets/OwnershipFacet.sol";
import "../src/diamond/upgradeInitializers/PKPToolRegistryInit.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/facets/PKPToolRegistryPolicyParameterFacet.sol";
import "../src/abstract/PKPToolRegistryBase.sol";
import "../src/diamond/interfaces/IDiamondCut.sol";
import "../src/diamond/interfaces/IDiamondLoupe.sol";
import "../src/diamond/interfaces/IERC165.sol";
import "../src/diamond/interfaces/IERC173.sol";
import "../src/diamond/interfaces/IDiamond.sol";

/// @title PKP Tool Registry Deployment Script
/// @notice Foundry script for deploying the PKP Tool Registry Diamond to multiple networks
/// @dev Uses environment variables for private key and PKP NFT contract addresses
/// @custom:env PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY - Private key of the deployer
/// @custom:env DATIL_DEV_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil Dev
/// @custom:env DATIL_TEST_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil Test
/// @custom:env DATIL_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil
contract DeployPKPToolRegistry is Script {
    /// @notice Error thrown when required environment variables are missing
    error MissingEnvironmentVariable(string name);

    /// @notice Deploy facets for the diamond
    /// @return facets Array of deployed facet addresses and their cut data
    /// @return diamondCutFacetAddress Address of the DiamondCutFacet
    function deployFacets() internal returns (IDiamond.FacetCut[] memory, address) {
        // Deploy facets
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        PKPToolRegistryPolicyFacet policyFacet = new PKPToolRegistryPolicyFacet();
        PKPToolRegistryToolFacet toolFacet = new PKPToolRegistryToolFacet();
        PKPToolRegistryDelegateeFacet delegateeFacet = new PKPToolRegistryDelegateeFacet();
        PKPToolRegistryPolicyParameterFacet policyParameterFacet = new PKPToolRegistryPolicyParameterFacet();

        // Build cut struct for adding facets
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](6);

        // Add DiamondLoupeFacet
        cut[0] = IDiamond.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getDiamondLoupeFacetSelectors()
        });

        // Add OwnershipFacet
        cut[1] = IDiamond.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getOwnershipFacetSelectors()
        });

        // Add PolicyFacet
        cut[2] = IDiamond.FacetCut({
            facetAddress: address(policyFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getPolicyFacetSelectors()
        });

        // Add ToolFacet
        cut[3] = IDiamond.FacetCut({
            facetAddress: address(toolFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getToolFacetSelectors()
        });

        // Add DelegateeFacet
        cut[4] = IDiamond.FacetCut({
            facetAddress: address(delegateeFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getDelegateeFacetSelectors()
        });

        // Add PolicyParameterFacet
        cut[5] = IDiamond.FacetCut({
            facetAddress: address(policyParameterFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: getPolicyParameterFacetSelectors()
        });

        return (cut, address(diamondCutFacet));
    }

    /// @notice Log deployment details
    /// @param network Network name
    /// @param diamond Diamond contract address
    /// @param pkpNFTAddress PKP NFT contract address
    /// @param facets Array of deployed facet addresses
    function logDeployment(
        string memory network,
        address diamond,
        address pkpNFTAddress,
        IDiamond.FacetCut[] memory facets
    ) internal view {
        console.log("PKPToolRegistry Diamond deployed for", network, "to:", address(diamond));
        console.log("Using PKP NFT contract:", pkpNFTAddress);
        for (uint256 i = 0; i < facets.length;) {
            console.log(string.concat("Facet ", vm.toString(i), ":"), facets[i].facetAddress);
            unchecked { ++i; }
        }
    }

    /// @notice Deploy to a specific network
    /// @param network Network name for logging
    /// @param pkpNFTAddress PKP NFT contract address
    /// @return address The address of the deployed registry
    function deployToNetwork(string memory network, address pkpNFTAddress) public returns (address) {
        // Validate PKP NFT address
        if (pkpNFTAddress == address(0)) {
            revert MissingEnvironmentVariable(string.concat(network, " PKP NFT contract address"));
        }

        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert MissingEnvironmentVariable("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY");
        }
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy facets and get cut data
        (IDiamond.FacetCut[] memory cut, address diamondCutFacetAddress) = deployFacets();

        // Deploy initialization contract
        PKPToolRegistryInit initContract = new PKPToolRegistryInit();

        // Deploy the Diamond with the diamondCut facet and owner
        PKPToolRegistry diamond = new PKPToolRegistry(
            vm.addr(deployerPrivateKey), // contract owner
            diamondCutFacetAddress,
            pkpNFTAddress
        );

        // Execute diamond cut to add facets
        bytes memory initCalldata = abi.encodeWithSelector(PKPToolRegistryInit.init.selector, pkpNFTAddress);
        IDiamondCut(address(diamond)).diamondCut(cut, address(initContract), initCalldata);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment details
        logDeployment(network, address(diamond), pkpNFTAddress, cut);

        return address(diamond);
    }

    /// @notice Get function selectors for a facet
    /// @dev Returns the function selectors for each facet
    /// @param facetName The name of the facet to get selectors for
    /// @return selectors Array of function selectors for the facet
    function getFunctionSelectors(string memory facetName) public pure returns (bytes4[] memory) {
        if (equal(facetName, "DiamondLoupeFacet")) {
            return getDiamondLoupeFacetSelectors();
        }
        if (equal(facetName, "OwnershipFacet")) {
            return getOwnershipFacetSelectors();
        }
        if (equal(facetName, "PKPToolRegistryPolicyFacet")) {
            return getPolicyFacetSelectors();
        }
        if (equal(facetName, "PKPToolRegistryToolFacet")) {
            return getToolFacetSelectors();
        }
        if (equal(facetName, "PKPToolRegistryDelegateeFacet")) {
            return getDelegateeFacetSelectors();
        }
        if (equal(facetName, "PKPToolRegistryPolicyParameterFacet")) {
            return getPolicyParameterFacetSelectors();
        }
        return new bytes4[](0);
    }

    function getDiamondLoupeFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = IDiamondLoupe.facets.selector;
        selectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        selectors[2] = IDiamondLoupe.facetAddresses.selector;
        selectors[3] = IDiamondLoupe.facetAddress.selector;
        selectors[4] = IERC165.supportsInterface.selector;
        return selectors;
    }

    function getOwnershipFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = IERC173.owner.selector;
        selectors[1] = IERC173.transferOwnership.selector;
        return selectors;
    }

    function getPolicyFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = PKPToolRegistryPolicyFacet.getEffectiveToolPolicyForDelegatee.selector;
        selectors[1] = PKPToolRegistryPolicyFacet.getCustomToolPolicyForDelegatee.selector;
        selectors[2] = PKPToolRegistryPolicyFacet.setCustomToolPoliciesForDelegatees.selector;
        selectors[3] = PKPToolRegistryPolicyFacet.removeCustomToolPoliciesForDelegatees.selector;
        selectors[4] = PKPToolRegistryPolicyFacet.enableCustomToolPoliciesForDelegatees.selector;
        selectors[5] = PKPToolRegistryPolicyFacet.disableCustomToolPoliciesForDelegatees.selector;
        return selectors;
    }

    function getToolFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = PKPToolRegistryToolFacet.isToolRegistered.selector;
        selectors[1] = PKPToolRegistryToolFacet.isToolPermittedForDelegatee.selector;
        selectors[2] = PKPToolRegistryToolFacet.getRegisteredTools.selector;
        selectors[3] = PKPToolRegistryToolFacet.getRegisteredToolsAndPolicies.selector;
        selectors[4] = PKPToolRegistryToolFacet.getToolsWithPolicy.selector;
        selectors[5] = PKPToolRegistryToolFacet.getToolsWithoutPolicy.selector;
        selectors[6] = PKPToolRegistryToolFacet.registerTools.selector;
        selectors[7] = PKPToolRegistryToolFacet.removeTools.selector;
        selectors[8] = PKPToolRegistryToolFacet.enableTools.selector;
        selectors[9] = PKPToolRegistryToolFacet.disableTools.selector;
        selectors[10] = PKPToolRegistryBase.getPKPNFTContract.selector;
        selectors[11] = PKPToolRegistryToolFacet.permitToolsForDelegatees.selector;
        selectors[12] = PKPToolRegistryToolFacet.unpermitToolsForDelegatees.selector;
        return selectors;
    }

    function getDelegateeFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = PKPToolRegistryDelegateeFacet.getDelegatees.selector;
        selectors[1] = PKPToolRegistryDelegateeFacet.isPkpDelegatee.selector;
        selectors[2] = PKPToolRegistryDelegateeFacet.getDelegatedPkps.selector;
        selectors[3] = PKPToolRegistryDelegateeFacet.addDelegatees.selector;
        selectors[4] = PKPToolRegistryDelegateeFacet.removeDelegatees.selector;
        return selectors;
    }

    function getPolicyParameterFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = PKPToolRegistryPolicyParameterFacet.getToolPolicyParameterNamesForDelegatee.selector;
        selectors[1] = PKPToolRegistryPolicyParameterFacet.getToolPolicyParametersForDelegatee.selector;
        selectors[2] = PKPToolRegistryPolicyParameterFacet.setToolPolicyParametersForDelegatee.selector;
        selectors[3] = PKPToolRegistryPolicyParameterFacet.removeToolPolicyParametersForDelegatee.selector;
        return selectors;
    }

    /// @notice Compare two strings
    /// @dev Helper function to compare strings
    /// @param a First string
    /// @param b Second string
    /// @return bool True if strings are equal
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /// @notice Deploy to Datil Dev network
    function deployToDatilDev() public returns (address) {
        address pkpNFTAddress = vm.envAddress("DATIL_DEV_PKP_NFT_CONTRACT_ADDRESS");
        return deployToNetwork("Datil Dev", pkpNFTAddress);
    }

    /// @notice Deploy to Datil Test network
    function deployToDatilTest() public returns (address) {
        address pkpNFTAddress = vm.envAddress("DATIL_TEST_PKP_NFT_CONTRACT_ADDRESS");
        return deployToNetwork("Datil Test", pkpNFTAddress);
    }

    /// @notice Deploy to Datil network
    function deployToDatil() public returns (address) {
        address pkpNFTAddress = vm.envAddress("DATIL_PKP_NFT_CONTRACT_ADDRESS");
        return deployToNetwork("Datil", pkpNFTAddress);
    }

    /// @notice Main deployment function
    function run() public {
        // Deploy to all networks
        deployToDatilDev();
        deployToDatilTest();
        deployToDatil();
    }
} 