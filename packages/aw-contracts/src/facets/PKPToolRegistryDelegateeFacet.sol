// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";
import "../libraries/PKPToolRegistryDelegateeEvents.sol";

/// @title PKP Tool Policy Delegatee Management Facet
/// @notice Diamond facet for managing delegatees in the PKP tool policy system
/// @dev Inherits from PKPToolRegistryBase for common functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryDelegateeFacet is PKPToolRegistryBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get all delegatees for a PKP
    /// @dev Returns an array of all addresses that have been granted delegatee status
    /// @param pkpTokenId The PKP token ID
    /// @return Array of delegatee addresses in no particular order
    function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory) {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = pkpData.delegatees.length();
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length;) {
            result[i] = pkpData.delegatees.at(i);
            unchecked { ++i; }
        }
        return result;
    }

    /// @notice Check if an address is a delegatee of a PKP
    /// @dev Verifies if the address has been granted delegatee status
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The address to check
    /// @return bool True if the address is a delegatee, false otherwise
    function isPkpDelegatee(uint256 pkpTokenId, address delegatee) external view returns (bool) {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        return l.pkpStore[pkpTokenId].delegatees.contains(delegatee);
    }

    /// @notice Get all PKPs that have delegated to an address
    /// @dev Returns all PKP token IDs that have granted delegatee status to this address
    /// @param delegatee The delegatee address to query
    /// @return Array of PKP token IDs in no particular order
    function getDelegatedPkps(address delegatee) external view returns (uint256[] memory) {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        
        uint256 length = delegateeData.delegatedPkps.length();
        uint256[] memory result = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            result[i] = delegateeData.delegatedPkps.at(i);
            unchecked { ++i; }
        }
        return result;
    }

    /// @notice Add delegatees to a PKP
    /// @dev Only callable by PKP owner. For single delegatee operations, pass an array with one element
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses to add
    /// @custom:throws EmptyDelegatees if delegatees array is empty
    /// @custom:throws ZeroAddressCannotBeDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function addDelegatees(
        uint256 pkpTokenId,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolRegistryErrors.EmptyDelegatees();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < delegatees.length;) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee();
            
            // Add delegatee to PKP's set if not already present
            if (pkpData.delegatees.add(delegatee)) {
                // Add PKP to delegatee's set
                PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                delegateeData.delegatedPkps.add(pkpTokenId);
            }

            unchecked { ++i; }
        }

        emit PKPToolRegistryDelegateeEvents.AddedDelegatees(pkpTokenId, delegatees);
    }

    /// @notice Remove delegatees from a PKP
    /// @dev Only callable by PKP owner. For single delegatee operations, pass an array with one element
    /// @dev Removes all policies and permissions for the delegatees being removed
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses to remove
    /// @custom:throws EmptyDelegatees if delegatees array is empty
    /// @custom:throws ZeroAddressCannotBeDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function removeDelegatees(
        uint256 pkpTokenId,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolRegistryErrors.EmptyDelegatees();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < delegatees.length;) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee();

            // Remove delegatee from PKP's set if present
            if (pkpData.delegatees.remove(delegatee)) {
                // Clean up any policies this delegatee had
                _cleanupDelegateePolicies(pkpTokenId, delegatee);

                // Remove PKP from delegatee's set
                PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                delegateeData.delegatedPkps.remove(pkpTokenId);
            }

            unchecked { ++i; }
        }

        emit PKPToolRegistryDelegateeEvents.RemovedDelegatees(pkpTokenId, delegatees);
    }

    /// @notice Internal function to clean up policies when removing a delegatee
    /// @dev Removes all policies and permitted tools for a PKP-delegatee pair
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee being removed
    function _cleanupDelegateePolicies(uint256 pkpTokenId, address delegatee) internal {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        
        // Get all permitted tool CIDs for this PKP-delegatee pair
        EnumerableSet.Bytes32Set storage permittedTools = delegateeData.permittedToolsForPkp[pkpTokenId];
        bytes32[] memory permittedToolHashes = new bytes32[](permittedTools.length());
        for (uint256 i = 0; i < permittedTools.length();) {
            permittedToolHashes[i] = permittedTools.at(i);
            unchecked { ++i; }
        }

        // Remove all policies for this delegatee's permitted tools
        for (uint256 i = 0; i < permittedToolHashes.length;) {
            bytes32 toolCidHash = permittedToolHashes[i];
            PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

            // Remove from delegateesWithCustomPolicy if present
            if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                // Delete the policy
                delete tool.delegateeCustomPolicies[delegatee];
            }

            unchecked { ++i; }
        }

        // Clear the permitted tools set
        uint256 count = permittedTools.length();
        for (uint256 i = 0; i < count;) {
            permittedTools.remove(permittedTools.at(0));
            unchecked { ++i; }
        }
    }
} 