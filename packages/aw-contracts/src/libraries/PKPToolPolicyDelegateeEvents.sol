// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyDelegateeEvents {
    /// @notice Emitted when new delegatees are added to a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses
    event AddedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);

    /// @notice Emitted when multiple delegatees are removed from a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of removed delegatee addresses
    event RemovedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
} 