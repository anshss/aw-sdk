// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPKPNFTFacet {
    /// @dev Returns the owner of the NFT specified by tokenId.
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Custom errors for better gas efficiency and clearer error messages
error InvalidPKPTokenId();
error ActionNotFound(string ipfsCid);
error EmptyIPFSCID();
error EmptyPolicy();
error EmptyDelegatees();
error NotPKPOwner();
error EmptyVersion();

/// @dev Emitted when delegatees are set for a PKP
event NewDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
/// @dev Emitted when a delegatee is removed from a PKP
event DelegateeRemoved(uint256 indexed pkpTokenId, address indexed delegatee);
/// @dev Emitted when a tool policy is set or updated
event ActionPolicySet(
    uint256 indexed pkpTokenId,
    string ipfsCid,
    bytes policy,
    string version
);
/// @dev Emitted when a tool policy is removed
event ActionPolicyRemoved(uint256 indexed pkpTokenId, string ipfsCid);

/**
 * @title PKPToolPolicyRegistry
 * @dev Registry for managing PKP-specific tool policies. Each PKP's owner (admin)
 * can set policies for tools it wants to execute and manage delegatees who are
 * authorized to execute the tools.
 *
 * Each tool has a policy - Tool-specific configuration bytes that must be ABI encoded
 *
 * Policy Format:
 * The policy field must be ABI encoded data using abi.encode().
 * Example:
 * - abi.encode(uint256 maxAmount, address[] allowedTokens)
 * - abi.encode(bytes32 role, uint256 threshold)
 *
 * IPFS CID Format:
 * - Must be a valid IPFS CID v0 (e.g., "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGx")
 * - Represents the content hash of the tool code stored on IPFS
 * - CID v1 is not supported
 * - Cannot be empty
 *
 * Policies:
 * - Must not be empty (use removeActionPolicy to remove a policy)
 * - Must be properly ABI encoded
 * - Version must be specified
 */
contract PKPToolPolicyRegistry {
    /**
     * @dev Stores the policy for a specific tool
     * @param policy Tool-specific configuration bytes that must be ABI encoded using abi.encode()
     * @param version Version of the policy (e.g., "1.0.0")
     */
    struct ActionPolicy {
        bytes policy; // Tool-specific ABI encoded configuration bytes
        string version; // Version of the policy
    }

    /// @dev Reference to the PKP NFT contract
    IPKPNFTFacet public immutable PKPNFT_CONTRACT;

    /// @dev Maps PKP token ID -> list of delegatee addresses that can execute tools
    mapping(uint256 => address[]) public pkpDelegatees;

    /// @dev Maps PKP token ID -> delegatee address -> bool to check if address is delegatee
    mapping(uint256 => mapping(address => bool)) public isDelegatee;

    /// @dev Maps PKP token ID -> IPFS CID -> policy
    mapping(uint256 => mapping(string => ActionPolicy)) public policies;

    /// @dev Maps PKP token ID -> list of registered IPFS CIDs
    mapping(uint256 => string[]) internal registeredActions;

    /// @dev Maps PKP token ID -> IPFS CID -> index in registeredActions array
    mapping(uint256 => mapping(string => uint256)) internal actionIndices;

    /**
     * @dev Constructor to set the PKP NFT contract address
     * @param _pkpNFT Address of the PKP NFT contract
     */
    constructor(address _pkpNFT) {
        if (_pkpNFT == address(0)) revert InvalidPKPTokenId();
        PKPNFT_CONTRACT = IPKPNFTFacet(_pkpNFT);
    }

    /**
     * @dev Modifier to ensure only the owner of a PKP can call a function
     * @param pkpTokenId The PKP token ID to check ownership for
     */
    modifier onlyPKPOwner(uint256 pkpTokenId) {
        if (msg.sender != PKPNFT_CONTRACT.ownerOf(pkpTokenId)) revert NotPKPOwner();
        _;
    }

    /**
     * @dev Get all registered tools and their policies for a PKP
     * @param pkpTokenId The PKP token ID to get registered tools for
     * @return ipfsCids Array of IPFS CIDs for registered tools
     * @return policyData Array of ABI encoded policy structs
     * @return versions Array of policy versions
     */
    function getRegisteredActions(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory ipfsCids,
            bytes[] memory policyData,
            string[] memory versions
        )
    {
        string[] storage actionsList = registeredActions[pkpTokenId];
        uint256 length = actionsList.length;

        ipfsCids = new string[](length);
        policyData = new bytes[](length);
        versions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            string memory currentCid = actionsList[i];
            ipfsCids[i] = currentCid;
            
            ActionPolicy storage currentPolicy = policies[pkpTokenId][currentCid];
            policyData[i] = currentPolicy.policy;
            versions[i] = currentPolicy.version;
        }

        return (ipfsCids, policyData, versions);
    }

    /**
     * @dev Get the policy for a specific tool
     * @param pkpTokenId The PKP token ID to get the policy for
     * @param ipfsCid IPFS CID of the tool
     * @return policy The ABI encoded policy struct
     * @return version Version of the policy
     */
    function getActionPolicy(uint256 pkpTokenId, string calldata ipfsCid)
        external
        view
        returns (bytes memory policy, string memory version)
    {
        ActionPolicy storage actionPolicy = policies[pkpTokenId][ipfsCid];
        return (actionPolicy.policy, actionPolicy.version);
    }

    /**
     * @dev Set or update a policy for a specific tool
     * @notice This function must be called by the PKP's admin
     * @notice Use removeActionPolicy to remove a policy, not an empty policy
     * @param pkpTokenId The PKP token ID to set the policy for
     * @param ipfsCid IPFS CID of the tool
     * @param policy Tool-specific policy bytes that must be ABI encoded
     * @param version Version of the policy
     */
    function setActionPolicy(
        uint256 pkpTokenId,
        string calldata ipfsCid,
        bytes calldata policy,
        string calldata version
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(ipfsCid).length == 0) revert EmptyIPFSCID();
        if (policy.length == 0) revert EmptyPolicy();
        if (bytes(version).length == 0) revert EmptyVersion();

        ActionPolicy storage actionPolicy = policies[pkpTokenId][ipfsCid];

        // If this is a new action, add it to the list
        if (actionPolicy.policy.length == 0) {
            actionIndices[pkpTokenId][ipfsCid] = registeredActions[pkpTokenId].length;
            registeredActions[pkpTokenId].push(ipfsCid);
        }

        actionPolicy.policy = policy;
        actionPolicy.version = version;

        emit ActionPolicySet(pkpTokenId, ipfsCid, policy, version);
    }

    /**
     * @dev Remove a policy for a specific tool
     * @notice This function must be called by the PKP's admin
     * @param pkpTokenId The PKP token ID to remove the policy for
     * @param ipfsCid IPFS CID of the tool to remove
     */
    function removeActionPolicy(uint256 pkpTokenId, string calldata ipfsCid) external onlyPKPOwner(pkpTokenId) {
        if (bytes(ipfsCid).length == 0) revert EmptyIPFSCID();

        // Get the index of the IPFS CID in the array
        uint256 index = actionIndices[pkpTokenId][ipfsCid];
        string[] storage actions = registeredActions[pkpTokenId];

        // Check if the action exists
        if (index >= actions.length || 
            keccak256(bytes(actions[index])) != keccak256(bytes(ipfsCid))) {
            revert ActionNotFound(ipfsCid);
        }

        // Get the last element's CID
        string memory lastCid = actions[actions.length - 1];

        // If we're not removing the last element, move the last element to the removed position
        if (index != actions.length - 1) {
            actions[index] = lastCid;
            actionIndices[pkpTokenId][lastCid] = index;
        }

        // Remove the last element and clean up storage
        actions.pop();
        delete policies[pkpTokenId][ipfsCid];
        delete actionIndices[pkpTokenId][ipfsCid];

        emit ActionPolicyRemoved(pkpTokenId, ipfsCid);
    }

    /**
     * @dev Get the list of delegatees for a PKP
     * @param pkpTokenId The PKP token ID to get delegatees for
     * @return Array of delegatee addresses
     */
    function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory) {
        return pkpDelegatees[pkpTokenId];
    }

    /**
     * @dev Check if an address is a delegatee for a PKP
     * @param pkpTokenId The PKP token ID to check
     * @param delegatee The address to check
     * @return bool True if the address is a delegatee
     */
    function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool) {
        return isDelegatee[pkpTokenId][delegatee];
    }

    /**
     * @dev Add a single delegatee for a PKP
     * @param pkpTokenId The PKP token ID to add delegatee for
     * @param delegatee Address to add as delegatee
     */
    function addDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert InvalidPKPTokenId();
        if (isDelegatee[pkpTokenId][delegatee]) return; // Already a delegatee

        pkpDelegatees[pkpTokenId].push(delegatee);
        isDelegatee[pkpTokenId][delegatee] = true;

        // Emit event with array containing only the new delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = delegatee;
        emit NewDelegatees(pkpTokenId, delegatees);
    }

    /**
     * @dev Remove a single delegatee for a PKP
     * @param pkpTokenId The PKP token ID to remove delegatee from
     * @param delegatee Address to remove as delegatee
     */
    function removeDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        if (!isDelegatee[pkpTokenId][delegatee]) return; // Not a delegatee

        address[] storage delegatees = pkpDelegatees[pkpTokenId];
        for (uint256 i = 0; i < delegatees.length; i++) {
            if (delegatees[i] == delegatee) {
                // Move the last element to the removed position
                delegatees[i] = delegatees[delegatees.length - 1];
                delegatees.pop();
                isDelegatee[pkpTokenId][delegatee] = false;
                
                emit DelegateeRemoved(pkpTokenId, delegatee);
                break;
            }
        }
    }

    /**
     * @dev Add multiple delegatees for a PKP
     * @param pkpTokenId The PKP token ID to add delegatees for
     * @param delegatees Array of addresses to add as delegatees
     */
    function batchAddDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert EmptyDelegatees();

        for (uint256 i = 0; i < delegatees.length; i++) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert InvalidPKPTokenId();
            if (!isDelegatee[pkpTokenId][delegatee]) {
                pkpDelegatees[pkpTokenId].push(delegatee);
                isDelegatee[pkpTokenId][delegatee] = true;
            }
        }

        emit NewDelegatees(pkpTokenId, delegatees);
    }

    /**
     * @dev Remove multiple delegatees for a PKP
     * @param pkpTokenId The PKP token ID to remove delegatees from
     * @param delegateesToRemove Array of addresses to remove as delegatees
     */
    function batchRemoveDelegatees(uint256 pkpTokenId, address[] calldata delegateesToRemove) external onlyPKPOwner(pkpTokenId) {
        if (delegateesToRemove.length == 0) revert EmptyDelegatees();

        address[] storage delegatees = pkpDelegatees[pkpTokenId];
        
        // For each delegatee to remove
        for (uint256 i = 0; i < delegateesToRemove.length; i++) {
            address delegatee = delegateesToRemove[i];
            if (isDelegatee[pkpTokenId][delegatee]) {
                // Find and remove from array
                for (uint256 j = 0; j < delegatees.length; j++) {
                    if (delegatees[j] == delegatee) {
                        // Move the last element to the removed position
                        delegatees[j] = delegatees[delegatees.length - 1];
                        delegatees.pop();
                        isDelegatee[pkpTokenId][delegatee] = false;
                        emit DelegateeRemoved(pkpTokenId, delegatee);
                        break;
                    }
                }
            }
        }
    }
}
