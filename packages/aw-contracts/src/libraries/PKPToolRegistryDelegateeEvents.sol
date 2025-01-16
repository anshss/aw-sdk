// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Registry Delegatee Events Library
/// @notice Events emitted during delegatee management operations
/// @dev Contains events for adding and removing delegatees from PKPs
library PKPToolRegistryDelegateeEvents {
    /// @notice Emitted when new delegatees are granted permissions for a PKP
    /// @dev Adding a delegatee allows them to use tools according to their policies
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param delegatees Array of addresses being granted delegatee status
    event AddedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);

    /// @notice Emitted when delegatees have their permissions revoked from a PKP
    /// @dev Removing a delegatee revokes all their tool permissions and policies
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param delegatees Array of addresses having their delegatee status revoked
    event RemovedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
} 