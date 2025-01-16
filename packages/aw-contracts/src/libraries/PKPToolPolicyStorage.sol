// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library PKPToolPolicyStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 internal constant STORAGE_SLOT = keccak256("lit.pkptoolpolicy.storage");

    /// @notice Stores all tool-related data for a single PKP
    struct PKPData {
        EnumerableSet.AddressSet delegatees;               // Set of all delegatees
        EnumerableSet.Bytes32Set toolCids;                 // Set of all registered tool CIDs (hashed)
        mapping(bytes32 => ToolInfo) toolMap;              // Mapping from tool CID hash to its data
    }

    /// @notice Represents a delegatee with associated PKPs
    struct Delegatee {
        EnumerableSet.UintSet delegatedPkps;                                // Set of PKP token IDs the delegatee has been delegated some usage of
        mapping(uint256 => EnumerableSet.Bytes32Set) permittedToolsForPkp;   // Mapping from PKP token ID to tool IPFS CIDs (hashed) the delegatee is permitted to use
    }

    /// @notice Stores all information about a single tool for a PKP
    struct ToolInfo {
        bool enabled;                            // Whether this tool is enabled
        Policy blanketPolicy;                    // The blanket policy for this tool
        EnumerableSet.AddressSet delegateesWithCustomPolicy;  // Set of delegatees that have a custom policy
        mapping(address => Policy) delegateeCustomPolicies;   // Delegatee-specific policies
    }

    /// @notice Represents a policy with its enabled state and IPFS CID
    struct Policy {
        bool enabled;                           // Whether this policy is currently enabled
        bytes32 policyIpfsCidHash;             // Hash of the policy IPFS CID
        EnumerableSet.Bytes32Set parameterNames;   // Set of parameter names (hashed)
        mapping(bytes32 => bytes) parameters;      // Mapping from hashed parameter names to values
    }

    struct Layout {
        // PKP NFT contract reference
        address pkpNftContract;

        // Unified tool storage
        mapping(uint256 => PKPData) pkpStore;

        // Delegatee management
        mapping(address => Delegatee) delegatees;

        // String storage mappings
        mapping(bytes32 => string) hashedToolCidToOriginalCid;      // Maps hashed tool CID to original IPFS CID string
        mapping(bytes32 => string) hashedParameterNameToOriginalName;  // Maps hashed parameter name to original parameter name string
        mapping(bytes32 => string) hashedPolicyCidToOriginalCid;    // Maps hashed policy CID to original IPFS CID string
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
} 