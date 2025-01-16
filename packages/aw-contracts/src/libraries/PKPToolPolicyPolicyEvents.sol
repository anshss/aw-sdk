// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyPolicyEvents {
    event ToolPoliciesSet(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees,
        string[] policyIpfsCids
    );

    event ToolPoliciesRemoved(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    /// @notice Emitted when multiple policies are enabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    event PoliciesEnabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    /// @notice Emitted when multiple policies are disabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    event PoliciesDisabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        address[] delegatees
    );

    event BlanketPoliciesSet(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids,
        string[] policyIpfsCids
    );

    event BlanketPoliciesRemoved(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );

    /// @notice Emitted when multiple blanket policies are enabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event BlanketPoliciesEnabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );

    /// @notice Emitted when multiple blanket policies are disabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event BlanketPoliciesDisabled(
        uint256 indexed pkpTokenId,
        string[] toolIpfsCids
    );
} 