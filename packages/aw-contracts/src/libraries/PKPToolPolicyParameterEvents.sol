// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Policy Parameter Events Library
/// @notice Events emitted during parameter management operations
/// @dev Contains events for both blanket and delegatee-specific parameter operations
library PKPToolPolicyParameterEvents {
    /// @notice Emitted when parameters are set in a blanket policy
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names that were set
    /// @param parameterValues Array of corresponding parameter values
    event BlanketPolicyParametersSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames,
        bytes[] parameterValues
    );

    /// @notice Emitted when parameters are removed from a blanket policy
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names that were removed
    event BlanketPolicyParametersRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames
    );

    /// @notice Emitted when parameters are set in a delegatee-specific policy
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The address of the delegatee (indexed for efficient filtering)
    /// @param parameterNames Array of parameter names that were set
    /// @param parameterValues Array of corresponding parameter values
    event PolicyParametersSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string[] parameterNames,
        bytes[] parameterValues
    );

    /// @notice Emitted when parameters are removed from a delegatee-specific policy
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The address of the delegatee (indexed for efficient filtering)
    /// @param parameterNames Array of parameter names that were removed
    event PolicyParametersRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string[] parameterNames
    );
} 