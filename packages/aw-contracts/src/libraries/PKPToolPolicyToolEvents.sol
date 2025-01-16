// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyToolEvents {
    /// @notice Emitted when multiple tools are registered
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event ToolsRegistered(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when multiple tools are removed
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when multiple tools are enabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);

    /// @notice Emitted when multiple tools are disabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
} 