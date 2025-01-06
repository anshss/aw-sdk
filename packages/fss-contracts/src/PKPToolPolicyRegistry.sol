// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPKPNFTFacet {
    /// @dev Returns the owner of the NFT specified by tokenId.
    function ownerOf(uint256 tokenId) external view returns (address);
}

// Custom errors for better gas efficiency and clearer error messages
error InvalidPKPTokenId();
error ToolNotFound(string ipfsCid);
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
event ToolPolicySet(
    uint256 indexed pkpTokenId,
    string ipfsCid,
    bytes policy,
    string version
);
/// @dev Emitted when a tool policy is removed
event ToolPolicyRemoved(uint256 indexed pkpTokenId, string ipfsCid);

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
 * - Must not be empty (use removeToolPolicy to remove a policy)
 * - Must be properly ABI encoded
 * - Version must be specified
 */
contract PKPToolPolicyRegistry {
    /**
     * @dev Stores the policy for a specific tool
     * @param policy Tool-specific configuration bytes that must be ABI encoded using abi.encode()
     * @param version Version of the policy (e.g., "1.0.0")
     */
    struct ToolPolicy {
        bytes policy; // Tool-specific ABI encoded configuration bytes
        string version; // Version of the policy
    }

    /// @dev Reference to the PKP NFT contract
    IPKPNFTFacet public immutable PKPNFT_CONTRACT;

    /// @dev Maps PKP token ID -> list of delegatee addresses that can execute tools
    mapping(uint256 => address[]) public pkpDelegatees;

    /// @dev Maps PKP token ID -> delegatee address -> bool to check if address is delegatee
    mapping(uint256 => mapping(address => bool)) public isDelegatee;

    /// @dev Maps delegatee address -> list of PKP token IDs they are delegated to
    mapping(address => uint256[]) public delegateePkps;

    /// @dev Maps delegatee address -> PKP token ID -> index in delegateePkps array
    mapping(address => mapping(uint256 => uint256)) internal delegateePkpIndices;

    /// @dev Maps PKP token ID -> IPFS CID -> policy
    mapping(uint256 => mapping(string => ToolPolicy)) public policies;

    /// @dev Maps PKP token ID -> list of registered IPFS CIDs
    mapping(uint256 => string[]) internal registeredTools;

    /// @dev Maps PKP token ID -> IPFS CID -> index in registeredTools array
    mapping(uint256 => mapping(string => uint256)) internal toolIndices;

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
    function getRegisteredTools(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory ipfsCids,
            bytes[] memory policyData,
            string[] memory versions
        )
    {
        string[] storage toolsList = registeredTools[pkpTokenId];
        uint256 length = toolsList.length;

        ipfsCids = new string[](length);
        policyData = new bytes[](length);
        versions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            string memory currentCid = toolsList[i];
            ipfsCids[i] = currentCid;
            
            ToolPolicy storage currentPolicy = policies[pkpTokenId][currentCid];
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
    function getToolPolicy(uint256 pkpTokenId, string calldata ipfsCid)
        external
        view
        returns (bytes memory policy, string memory version)
    {
        ToolPolicy storage toolPolicy = policies[pkpTokenId][ipfsCid];
        return (toolPolicy.policy, toolPolicy.version);
    }

    /**
     * @dev Set or update a policy for a specific tool
     * @notice This function must be called by the PKP's admin
     * @notice Use removeToolPolicy to remove a policy, not an empty policy
     * @param pkpTokenId The PKP token ID to set the policy for
     * @param ipfsCid IPFS CID of the tool
     * @param policy Tool-specific policy bytes that must be ABI encoded
     * @param version Version of the policy
     */
    function setToolPolicy(
        uint256 pkpTokenId,
        string calldata ipfsCid,
        bytes calldata policy,
        string calldata version
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(ipfsCid).length == 0) revert EmptyIPFSCID();
        if (policy.length == 0) revert EmptyPolicy();
        if (bytes(version).length == 0) revert EmptyVersion();

        ToolPolicy storage toolPolicy = policies[pkpTokenId][ipfsCid];

        // If this is a new tool, add it to the list
        if (toolPolicy.policy.length == 0) {
            toolIndices[pkpTokenId][ipfsCid] = registeredTools[pkpTokenId].length;
            registeredTools[pkpTokenId].push(ipfsCid);
        }

        toolPolicy.policy = policy;
        toolPolicy.version = version;

        emit ToolPolicySet(pkpTokenId, ipfsCid, policy, version);
    }

    /**
     * @dev Remove a policy for a specific tool
     * @notice This function must be called by the PKP's admin
     * @param pkpTokenId The PKP token ID to remove the policy for
     * @param ipfsCid IPFS CID of the tool to remove
     */
    function removeToolPolicy(uint256 pkpTokenId, string calldata ipfsCid) external onlyPKPOwner(pkpTokenId) {
        if (bytes(ipfsCid).length == 0) revert EmptyIPFSCID();

        // Get the index of the IPFS CID in the array
        uint256 index = toolIndices[pkpTokenId][ipfsCid];
        string[] storage tools = registeredTools[pkpTokenId];

        // Check if the tool exists
        if (index >= tools.length || 
            keccak256(bytes(tools[index])) != keccak256(bytes(ipfsCid))) {
            revert ToolNotFound(ipfsCid);
        }

        // Get the last element's CID
        string memory lastCid = tools[tools.length - 1];

        // If we're not removing the last element, move the last element to the removed position
        if (index != tools.length - 1) {
            tools[index] = lastCid;
            toolIndices[pkpTokenId][lastCid] = index;
        }

        // Remove the last element and clean up storage
        tools.pop();
        delete policies[pkpTokenId][ipfsCid];
        delete toolIndices[pkpTokenId][ipfsCid];

        emit ToolPolicyRemoved(pkpTokenId, ipfsCid);
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
     * @dev Get all PKPs that a delegatee has been delegated to
     * @param delegatee The delegatee address to get PKPs for
     * @return Array of PKP token IDs
     */
    function getDelegatedPkps(address delegatee) external view returns (uint256[] memory) {
        return delegateePkps[delegatee];
    }

    /**
     * @dev Add a single delegatee for a PKP
     * @param pkpTokenId The PKP token ID to add delegatee for
     * @param delegatee Address to add as delegatee
     */
    function addDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert InvalidPKPTokenId();
        if (isDelegatee[pkpTokenId][delegatee]) return; // Already a delegatee

        // Add to PKP's delegatees
        pkpDelegatees[pkpTokenId].push(delegatee);
        isDelegatee[pkpTokenId][delegatee] = true;

        // Add to delegatee's PKPs
        delegateePkpIndices[delegatee][pkpTokenId] = delegateePkps[delegatee].length;
        delegateePkps[delegatee].push(pkpTokenId);

        address[] memory singleDelegatee = new address[](1);
        singleDelegatee[0] = delegatee;
        emit NewDelegatees(pkpTokenId, singleDelegatee);
    }

    /**
     * @dev Remove a single delegatee for a PKP
     * @param pkpTokenId The PKP token ID to remove delegatee from
     * @param delegatee Address to remove as delegatee
     */
    function removeDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        if (!isDelegatee[pkpTokenId][delegatee]) return; // Not a delegatee

        // Remove from PKP's delegatees
        address[] storage delegatees = pkpDelegatees[pkpTokenId];
        for (uint256 i = 0; i < delegatees.length; i++) {
            if (delegatees[i] == delegatee) {
                delegatees[i] = delegatees[delegatees.length - 1];
                delegatees.pop();
                break;
            }
        }
        isDelegatee[pkpTokenId][delegatee] = false;

        // Remove from delegatee's PKPs
        uint256[] storage pkps = delegateePkps[delegatee];
        uint256 index = delegateePkpIndices[delegatee][pkpTokenId];
        if (index < pkps.length - 1) {
            uint256 lastPkp = pkps[pkps.length - 1];
            pkps[index] = lastPkp;
            delegateePkpIndices[delegatee][lastPkp] = index;
        }
        pkps.pop();
        delete delegateePkpIndices[delegatee][pkpTokenId];

        emit DelegateeRemoved(pkpTokenId, delegatee);
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
