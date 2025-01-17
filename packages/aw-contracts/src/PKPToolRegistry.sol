// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./diamond/interfaces/IDiamondCut.sol";
import "./diamond/interfaces/IDiamondLoupe.sol";
import "./diamond/interfaces/IERC165.sol";
import "./diamond/interfaces/IERC173.sol";
import "./diamond/libraries/LibDiamond.sol";
import "./libraries/PKPToolRegistryStorage.sol";
import "./libraries/PKPToolRegistryErrors.sol";

/// @title PKP Tool Registry Diamond
/// @notice Core contract for managing programmable PKP tool policies using Lit Actions
/// @dev Implements EIP-2535 Diamond Standard for upgradeable policy management
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistry {
    /// @custom:throws InvalidPKPTokenId if _pkpNFT is the zero address
    constructor(address _contractOwner, address _diamondCutFacet, address _pkpNFT) payable {
        if (_pkpNFT == address(0)) revert PKPToolRegistryErrors.InvalidPKPTokenId();
        
        // Initialize diamond with owner and diamondCut facet
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // Add the diamondCut external function from the diamondCutFacet
        IDiamond.FacetCut[] memory cut = new IDiamond.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamond.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
        
        // Initialize PKPToolRegistry storage
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        l.pkpNftContract = _pkpNFT;

        // Initialize ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {
        revert("Diamond: Does not accept direct ETH transfers");
    }
}
