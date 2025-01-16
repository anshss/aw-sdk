// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Policy Tool Events Library
/// @notice Events emitted during tool management operations
/// @dev Contains events for registering, removing, enabling, and disabling tools
library PKPToolPolicyToolEvents {
    /// @notice Emitted when new tools are registered for a PKP
    /// @dev Tools must be registered before they can be used in policies
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of IPFS CIDs for the tools being registered
    event ToolsRegistered(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when tools are removed from a PKP
    /// @dev Removing a tool also removes all associated policies and parameters
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of IPFS CIDs for the tools being removed
    event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when previously registered tools are enabled
    /// @dev Only enabled tools can be used in active policies
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of IPFS CIDs for the tools being enabled
    event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when tools are temporarily disabled
    /// @dev Disabled tools remain registered but cannot be used in active policies
    /// @param pkpTokenId The ID of the PKP token (indexed for efficient filtering)
    /// @param toolIpfsCids Array of IPFS CIDs for the tools being disabled
    event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
} 