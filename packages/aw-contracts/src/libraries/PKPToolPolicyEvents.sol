// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyEvents {
    /// @notice Emitted when new delegatees are added to a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses
    event NewDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
    
    /// @notice Emitted when a delegatee is removed from a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The removed delegatee address
    event DelegateeRemoved(
        uint256 indexed pkpTokenId,
        address indexed delegatee
    );

    /// @notice Emitted when a policy is set for a tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (address(0) for blanket policies)
    /// @param policyIpfsCid The IPFS CID of the policy
    event ToolPolicySet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string policyIpfsCid
    );

    /// @notice Emitted when a policy is removed
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    event ToolPolicyRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee
    );

    /// @notice Emitted when a policy parameter is set
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    /// @param parameterName The name of the parameter
    /// @param parameterValue The value of the parameter
    event PolicyParameterSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string parameterName,
        bytes parameterValue
    );

    /// @notice Emitted when a policy parameter is removed
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    /// @param parameterName The name of the parameter
    event PolicyParameterRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string parameterName
    );

    event ToolRegistered(
        uint256 indexed pkpTokenId,
        string toolIpfsCid
    );

    event ToolRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid
    );
} 