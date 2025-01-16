// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title PKP Tool Policy Storage Library
/// @notice Manages storage layout for PKP tool policies, delegatees, and parameters
/// @dev Uses OpenZeppelin's EnumerableSet for efficient set operations and diamond storage pattern
library PKPToolPolicyStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Diamond storage slot for this library
    /// @notice Unique storage position to avoid storage collisions in the diamond
    bytes32 internal constant STORAGE_SLOT = keccak256("lit.pkptoolpolicy.storage");

    /// @notice Stores all tool-related data for a single PKP
    /// @dev Uses EnumerableSets for efficient membership checks and iteration
    struct PKPData {
        /// @notice Set of all delegatees that have been granted any permissions
        EnumerableSet.AddressSet delegatees;
        /// @notice Set of all registered tool CIDs (stored as keccak256 hashes)
        EnumerableSet.Bytes32Set toolCids;
        /// @notice Maps tool CID hashes to their complete information
        mapping(bytes32 => ToolInfo) toolMap;
    }

    /// @notice Represents a delegatee with their associated PKPs and permissions
    /// @dev Tracks both delegated PKPs and tool permissions per PKP
    struct Delegatee {
        /// @notice Set of PKP token IDs this delegatee has been granted access to
        EnumerableSet.UintSet delegatedPkps;
        /// @notice Maps PKP token IDs to the set of tool CIDs (hashed) the delegatee can use
        mapping(uint256 => EnumerableSet.Bytes32Set) permittedToolsForPkp;
    }

    /// @notice Stores all information about a single tool for a PKP
    /// @dev Includes both blanket and delegatee-specific policies
    struct ToolInfo {
        /// @notice Whether this tool is currently enabled
        bool enabled;
        /// @notice The default policy that applies when no delegatee-specific policy exists
        Policy blanketPolicy;
        /// @notice Set of delegatees that have custom policies for this tool
        EnumerableSet.AddressSet delegateesWithCustomPolicy;
        /// @notice Maps delegatee addresses to their custom policies
        mapping(address => Policy) delegateeCustomPolicies;
    }

    /// @notice Represents a policy with its configuration and parameters
    /// @dev Uses EnumerableSet for parameter names to allow iteration
    struct Policy {
        /// @notice Whether this policy is currently active
        bool enabled;
        /// @notice Hash of the policy's IPFS CID for efficient storage and comparison
        bytes32 policyIpfsCidHash;
        /// @notice Set of parameter names (stored as keccak256 hashes)
        EnumerableSet.Bytes32Set parameterNames;
        /// @notice Maps parameter name hashes to their values
        mapping(bytes32 => bytes) parameters;
    }

    /// @notice Main storage layout for the entire system
    /// @dev Uses diamond storage pattern for upgradeable contracts
    struct Layout {
        /// @notice Address of the PKP NFT contract for ownership verification
        address pkpNftContract;

        /// @notice Maps PKP token IDs to their complete tool and policy data
        mapping(uint256 => PKPData) pkpStore;

        /// @notice Maps delegatee addresses to their complete delegation data
        mapping(address => Delegatee) delegatees;

        /// @notice Maps hashed tool CIDs to their original IPFS CID strings
        mapping(bytes32 => string) hashedToolCidToOriginalCid;
        /// @notice Maps hashed parameter names to their original string names
        mapping(bytes32 => string) hashedParameterNameToOriginalName;
        /// @notice Maps hashed policy CIDs to their original IPFS CID strings
        mapping(bytes32 => string) hashedPolicyCidToOriginalCid;
    }

    /// @notice Retrieves the storage layout for this library
    /// @dev Uses assembly to access the diamond storage slot
    /// @return l The storage layout struct
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
} 