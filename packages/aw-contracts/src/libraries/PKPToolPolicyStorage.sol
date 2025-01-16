// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("lit.pkptoolpolicy.storage");

    /// @notice Stores all tool-related data for a single PKP
    struct PKPData {
        address[] delegatees;  // Array of all delegatees
        mapping(address => uint256) delegateeIndices;  // Index of each delegatee in the delegatees array
        string[] toolCids;  // Array of all registered tool CIDs
        mapping(string => uint256) toolCidIndices;  // Index of each tool CID in the toolCids array
        mapping(string => ToolInfo) toolMap;  // Mapping from tool CID to its data
    }

    /// @notice Represents a delegatee with associated PKPs
    struct Delegatee {
        uint256[] delegatedPkps;  // Array of PKP token IDs the delegatee has been delegated some usage of
        mapping(uint256 => uint256) delegatedPkpIndices;  // Index of each PKP token ID in the delegatedPkps array
        mapping(uint256 => string[]) permittedToolsForPkp;  // Mapping from PKP token ID to tool IPFS CIDs the delegatee is permitted to use
        mapping(uint256 => mapping(string => uint256)) permittedToolIndices;  // Index of each tool IPFS CID in the permittedToolsForPkp array
    }

    /// @notice Stores all information about a single tool for a PKP
    struct ToolInfo {
        bool enabled;             // Whether this tool is enabled
        string toolIpfsCid;        // The IPFS CID of the tool
        Policy blanketPolicy;      // The blanket policy for this tool
        address[] delegateesWithCustomPolicy;  // List of delegatees that have a custom policy
        mapping(address => uint256) delegateeCustomPolicyIndices;  // Index of each delegatee in the delegateesWithCustomPolicy array
        mapping(address => Policy) delegateeCustomPolicies;  // Delegatee-specific policies
    }

    /// @notice Represents a policy with its enabled state and IPFS CID
    struct Policy {
        bool enabled;              // Whether this policy is currently enabled
        string ipfsCid;           // The IPFS CID of the policy
        string[] parameterNames;   // Names of parameters set for this policy
        mapping(string => uint256) parameterNameIndices;  // Index of each parameter name in the parameterNames array
        mapping(string => bytes) parameters;  // Parameter values by name
    }

    struct Layout {
        // PKP NFT contract reference
        address pkpNftContract;

        // Unified tool storage
        mapping(uint256 => PKPData) pkpStore;

        // Delegatee management
        mapping(address => Delegatee) delegatees;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
} 