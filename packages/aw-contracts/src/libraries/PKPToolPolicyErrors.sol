// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Policy Error Library
/// @notice Collection of custom errors used throughout the PKP tool policy system
/// @dev All errors are defined here to ensure consistency across the system
library PKPToolPolicyErrors {
    /// @notice Thrown when a non-owner tries to perform an owner-only action
    error NotPKPOwner();

    /// @notice Thrown when an empty IPFS CID is provided for a tool
    error EmptyIPFSCID();

    /// @notice Thrown when an empty IPFS CID is provided for a policy
    error EmptyPolicyIPFSCID();

    /// @notice Thrown when attempting to access a tool that doesn't exist
    /// @param toolIpfsCid The IPFS CID of the tool that wasn't found
    error ToolNotFound(string toolIpfsCid);

    /// @notice Thrown when attempting to register a tool that's already registered
    /// @param toolIpfsCid The IPFS CID of the tool that already exists
    error ToolAlreadyExists(string toolIpfsCid);

    /// @notice Thrown when a policy parameter is invalid or malformed
    error InvalidPolicyParameter();

    /// @notice Thrown when trying to access or modify a non-existent policy
    error NoPolicySet();

    /// @notice Thrown when array lengths don't match in multi-parameter operations
    error ArrayLengthMismatch();

    /// @notice Thrown when an invalid PKP token ID is provided
    error InvalidPKPTokenId();

    /// @notice Thrown when trying to perform an operation with an empty delegatee list
    error EmptyDelegatees();

    /// @notice Thrown when a delegatee address is invalid
    error InvalidDelegatee();

    /// @notice Thrown when attempting to set the zero address as a delegatee
    error ZeroAddressCannotBeDelegatee();

    /// @notice Thrown when attempting to add a delegatee that's already registered
    /// @param pkpTokenId The ID of the PKP token
    /// @param delegatee The address of the delegatee that already exists
    error DelegateeAlreadyExists(uint256 pkpTokenId, address delegatee);

    /// @notice Thrown when attempting to access a delegatee that isn't registered
    /// @param pkpTokenId The ID of the PKP token
    /// @param delegatee The address of the delegatee that wasn't found
    error DelegateeNotFound(uint256 pkpTokenId, address delegatee);
} 