// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Registry Events Library
/// @notice Events emitted during policy management operations
/// @dev Contains events for both delegatee-specific and blanket policy operations
library PKPToolRegistryPolicyEvents {
    /// @notice Emitted when multiple delegatee-specific policies are set
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which policies were set
    /// @param delegatees Array of delegatee addresses for whom policies were set
    /// @param policyIpfsCids Array of policy IPFS CIDs that were set
    event ToolPoliciesSet(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees,
        string[] policyIpfsCids
    );

    /// @notice Emitted when multiple delegatee-specific policies are removed
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which policies were removed
    /// @param delegatees Array of delegatee addresses whose policies were removed
    event ToolPoliciesRemoved(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    /// @notice Emitted when multiple delegatee-specific policies are enabled
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which policies were enabled
    /// @param delegatees Array of delegatee addresses whose policies were enabled
    event PoliciesEnabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    /// @notice Emitted when multiple delegatee-specific policies are disabled
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which policies were disabled
    /// @param delegatees Array of delegatee addresses whose policies were disabled
    event PoliciesDisabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    /// @notice Emitted when multiple blanket policies are set
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which blanket policies were set
    /// @param policyIpfsCids Array of policy IPFS CIDs that were set as blanket policies
    event BlanketPoliciesSet(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        string[] policyIpfsCids
    );

    /// @notice Emitted when multiple blanket policies are removed
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which blanket policies were removed
    event BlanketPoliciesRemoved(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );

    /// @notice Emitted when multiple blanket policies are enabled
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which blanket policies were enabled
    event BlanketPoliciesEnabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );

    /// @notice Emitted when multiple blanket policies are disabled
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of tool IPFS CIDs for which blanket policies were disabled
    event BlanketPoliciesDisabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );
} 