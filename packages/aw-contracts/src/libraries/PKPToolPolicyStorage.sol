// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("lit.pkptoolpolicy.storage");

    struct Layout {
        // PKP NFT contract reference
        address pkpNftContract;

        // Delegatee mappings
        /// @notice Array of delegatee addresses for each PKP token ID
        /// @dev pkpTokenId => delegatee[]
        mapping(uint256 => address[]) pkpDelegatees;

        /// @notice Tracks whether an address is a delegatee for a specific PKP token ID
        /// @dev pkpTokenId => delegatee => isDelegatee
        mapping(uint256 => mapping(address => bool)) isDelegatee;

        /// @notice Array of PKP token IDs that an address is a delegatee for
        /// @dev delegatee => pkpTokenId[]
        mapping(address => uint256[]) delegateePkps;

        /// @notice Stores the index of a PKP token ID in the delegateePkps array for efficient removal
        /// @dev delegatee => pkpTokenId => index
        mapping(address => mapping(uint256 => uint256)) delegateePkpIndices;

        // Policy mappings
        /// @notice Stores the IPFS CID of the policy for each PKP token ID, tool, and delegatee
        /// @dev pkpTokenId => toolIpfsCid => delegatee => policyIpfsCid
        mapping(uint256 => mapping(string => mapping(address => string))) policies;

        /// @notice Stores the policy parameters for each PKP token ID, tool, delegatee, and parameter name
        /// @dev pkpTokenId => toolIpfsCid => delegatee => parameterName => parameterValue
        mapping(uint256 => mapping(string => mapping(address => mapping(string => bytes)))) policyParameters;
        
        // Mapping from PKP token ID => tool IPFS CID => delegatee address => parameter name => index in policyNames array
        mapping(uint256 => mapping(string => mapping(address => mapping(string => uint256)))) policyNameIndices;

        // Scoped policy names tracking
        /// @notice Array of policy parameter names for each PKP token ID, tool, and delegatee
        /// @dev pkpTokenId => toolIpfsCid => delegatee => parameterNames[]
        mapping(uint256 => mapping(string => mapping(address => string[]))) policyNames;

        /// @notice Tracks whether a policy parameter is registered to avoid duplicates
        /// @dev pkpTokenId => toolIpfsCid => delegatee => parameterName => isRegistered
        mapping(uint256 => mapping(string => mapping(address => mapping(string => bool)))) isPolicyParameterRegistered;

        // Tool tracking
        /// @notice Array of registered tool IPFS CIDs for each PKP token ID
        /// @dev pkpTokenId => toolIpfsCid[]
        mapping(uint256 => string[]) registeredTools;

        /// @notice Stores the index of a tool IPFS CID in the registeredTools array for efficient removal
        /// @dev pkpTokenId => toolIpfsCid => index
        mapping(uint256 => mapping(string => uint256)) toolIndices;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
} 