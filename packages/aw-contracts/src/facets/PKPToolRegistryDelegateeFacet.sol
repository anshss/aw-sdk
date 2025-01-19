// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryBase.sol";
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
        return pkpData.delegatees.values();
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
        return delegateeData.delegatedPkps.values();
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

        address[] memory addedDelegatees = new address[](delegatees.length);
        uint256 addedCount;

        for (uint256 i = 0; i < delegatees.length;) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee();
            
            // Add delegatee to PKP's set if not already present
            if (pkpData.delegatees.add(delegatee)) {
                // Add PKP to delegatee's set
                PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                delegateeData.delegatedPkps.add(pkpTokenId);
                addedDelegatees[addedCount++] = delegatee;
            }

            unchecked { ++i; }
        }

        if (addedCount > 0) {
            // Create a new array with exact size of added delegatees
            address[] memory trimmedAddedDelegatees = new address[](addedCount);
            for (uint256 i = 0; i < addedCount;) {
                trimmedAddedDelegatees[i] = addedDelegatees[i];
                unchecked { ++i; }
            }
            emit PKPToolRegistryDelegateeEvents.AddedDelegatees(pkpTokenId, trimmedAddedDelegatees);
        }
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

        address[] memory removedDelegatees = new address[](delegatees.length);
        uint256 removedCount;

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
                removedDelegatees[removedCount++] = delegatee;
            }

            unchecked { ++i; }
        }

        if (removedCount > 0) {
            // Create a new array with exact size of removed delegatees
            address[] memory trimmedRemovedDelegatees = new address[](removedCount);
            for (uint256 i = 0; i < removedCount;) {
                trimmedRemovedDelegatees[i] = removedDelegatees[i];
                unchecked { ++i; }
            }
            emit PKPToolRegistryDelegateeEvents.RemovedDelegatees(pkpTokenId, trimmedRemovedDelegatees);
        }
    }

    /// @notice Internal function to clean up policies when removing a delegatee
    /// @dev Removes all policies and permitted tools for a PKP-delegatee pair
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee being removed
    function _cleanupDelegateePolicies(uint256 pkpTokenId, address delegatee) internal {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        EnumerableSet.Bytes32Set storage permittedTools = delegateeData.permittedToolsForPkp[pkpTokenId];
        
        // Get all tools this delegatee has permissions for
        bytes32[] memory toolsToRemove = permittedTools.values();

        // Remove policies for each permitted tool
        for (uint256 i = 0; i < toolsToRemove.length;) {
            // Remove the policy if it exists
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolsToRemove[i]];
            if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                delete tool.delegateeCustomPolicies[delegatee];
            }

            // Remove the tool from permitted tools
            permittedTools.remove(toolsToRemove[i]);

            unchecked { ++i; }
        }
    }
} 