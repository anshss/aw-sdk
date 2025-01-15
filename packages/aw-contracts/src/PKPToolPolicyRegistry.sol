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
error EmptyPolicyIPFSCID();
error EmptyDelegatees();
error NotPKPOwner();
error InvalidPolicyParameter();

/// @dev Emitted when delegatees are set for a PKP
event NewDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
/// @dev Emitted when a delegatee is removed from a PKP
event DelegateeRemoved(uint256 indexed pkpTokenId, address indexed delegatee);
/// @dev Emitted when a tool policy is set or updated
event ToolPolicySet(
    uint256 indexed pkpTokenId,
    string ipfsCid,
    string policyIpfsCid,
    address delegatee // address(0) for blanket policies
);
/// @dev Emitted when a tool policy is removed
event ToolPolicyRemoved(uint256 indexed pkpTokenId, string ipfsCid, address delegatee);
event PolicyParameterSet(
    uint256 indexed pkpTokenId,
    string ipfsCid,
    address delegatee, // address(0) for blanket policies
    bytes4 parameterName,
    bytes parameterValue
);
event PolicyParameterRemoved(
    uint256 indexed pkpTokenId,
    string ipfsCid,
    address delegatee, // address(0) for blanket policies
    bytes4 parameterName
);

/**
 * @title PKPToolPolicyRegistry
 * @dev Registry for managing PKP-specific tool policies using Lit Actions.
 * Each PKP's owner can set policies for tools and manage delegatees who are
 * authorized to execute the tools.
 *
 * Each tool policy is a Lit Action that returns a boolean indicating whether
 * the execution is authorized. The policy can access on-chain parameters and
 * integrate with external services.
 *
 * Policy Format:
 * - Lit Action IPFS CID that returns { response: boolean }
 * - On-chain parameters accessible via bytes4(keccak256(parameterName))
 *
 * Policy Precedence:
 * - Delegatee-specific policies take precedence over blanket policies
 * - Blanket policies (set with delegatee = address(0)) apply to all delegatees
 *   unless they have a specific policy set
 *
 * IPFS CID Format:
 * - Must be a valid IPFS CID v0
 * - Represents either the tool code or policy code stored on IPFS
 * - Cannot be empty
 */
contract PKPToolPolicyRegistry {
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

    /// @dev Maps PKP token ID -> tool IPFS CID -> delegatee -> policy IPFS CID
    mapping(uint256 => mapping(string => mapping(address => string))) public policies;

    /// @dev Maps PKP token ID -> tool IPFS CID -> delegatee -> parameter name -> parameter value
    mapping(uint256 => mapping(string => mapping(address => mapping(bytes4 => bytes)))) public policyParameters;

    /// @dev Maps PKP token ID -> list of registered tool IPFS CIDs
    mapping(uint256 => string[]) internal registeredTools;

    /// @dev Maps PKP token ID -> tool IPFS CID -> index in registeredTools array
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
     * @dev Get all registered tools and their policies for a PKP and delegatee
     * @param pkpTokenId The PKP token ID
     * @param delegatee The delegatee address
     * @return toolIpfsCids Array of tool IPFS CIDs
     * @return policyIpfsCids Array of policy IPFS CIDs (delegatee-specific or blanket)
     */
    function getRegisteredTools(uint256 pkpTokenId, address delegatee)
        external
        view
        returns (string[] memory toolIpfsCids, string[] memory policyIpfsCids)
    {
        string[] storage toolsList = registeredTools[pkpTokenId];
        uint256 length = toolsList.length;

        toolIpfsCids = new string[](length);
        policyIpfsCids = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            string memory currentCid = toolsList[i];
            toolIpfsCids[i] = currentCid;
            
            // First try delegatee-specific policy
            string memory policy = policies[pkpTokenId][currentCid][delegatee];
            
            // If no delegatee-specific policy, use blanket policy
            if (bytes(policy).length == 0) {
                policy = policies[pkpTokenId][currentCid][address(0)];
            }
            
            policyIpfsCids[i] = policy;
        }

        return (toolIpfsCids, policyIpfsCids);
    }

    /**
     * @dev Get the policy for a specific tool and delegatee, respecting precedence
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param delegatee The delegatee address
     * @return policyIpfsCid The policy Lit Action IPFS CID (delegatee-specific or blanket)
     */
    function getToolPolicy(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee)
        external
        view
        returns (string memory policyIpfsCid)
    {
        // First try delegatee-specific policy
        policyIpfsCid = policies[pkpTokenId][toolIpfsCid][delegatee];
        
        // If no delegatee-specific policy, return blanket policy
        if (bytes(policyIpfsCid).length == 0) {
            policyIpfsCid = policies[pkpTokenId][toolIpfsCid][address(0)];
        }
        
        return policyIpfsCid;
    }

    /**
     * @dev Set or update a policy for a specific tool and optionally a delegatee
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param policyIpfsCid Policy Lit Action IPFS CID
     * @param delegatee The delegatee address (use address(0) for blanket policy)
     */
    function setToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata policyIpfsCid,
        address delegatee
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert EmptyIPFSCID();
        if (bytes(policyIpfsCid).length == 0) revert EmptyPolicyIPFSCID();

        // If this is a new tool, add it to the list
        if (toolIndices[pkpTokenId][toolIpfsCid] == 0 && registeredTools[pkpTokenId].length == 0) {
            toolIndices[pkpTokenId][toolIpfsCid] = registeredTools[pkpTokenId].length;
            registeredTools[pkpTokenId].push(toolIpfsCid);
        }

        policies[pkpTokenId][toolIpfsCid][delegatee] = policyIpfsCid;

        emit ToolPolicySet(pkpTokenId, toolIpfsCid, policyIpfsCid, delegatee);
    }

    /**
     * @dev Remove a policy for a specific tool and delegatee
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param delegatee The delegatee address
     */
    function removeToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert EmptyIPFSCID();
        if (delegatee == address(0)) revert InvalidPKPTokenId();

        delete policies[pkpTokenId][toolIpfsCid][delegatee];

        // Clean up policy parameters
        // Note: We don't enumerate and delete all parameters as it would be gas intensive
        // Parameters can be overwritten when needed

        emit ToolPolicyRemoved(pkpTokenId, toolIpfsCid, delegatee);
    }

    /**
     * @dev Set a policy parameter value
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param delegatee The delegatee address
     * @param parameterName The parameter name (as bytes4(keccak256(name)))
     * @param parameterValue The parameter value
     */
    function setPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        bytes4 parameterName,
        bytes calldata parameterValue
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert EmptyIPFSCID();
        if (delegatee == address(0)) revert InvalidPKPTokenId();
        if (parameterName == bytes4(0)) revert InvalidPolicyParameter();
        if (parameterValue.length == 0) revert InvalidPolicyParameter();

        policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName] = parameterValue;

        emit PolicyParameterSet(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterName,
            parameterValue
        );
    }

    /**
     * @dev Remove a policy parameter
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param delegatee The delegatee address
     * @param parameterName The parameter name (as bytes4(keccak256(name)))
     */
    function removePolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        bytes4 parameterName
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert EmptyIPFSCID();
        if (delegatee == address(0)) revert InvalidPKPTokenId();
        if (parameterName == bytes4(0)) revert InvalidPolicyParameter();

        delete policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName];

        emit PolicyParameterRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterName
        );
    }

    /**
     * @dev Get a policy parameter value, respecting precedence
     * @param pkpTokenId The PKP token ID
     * @param toolIpfsCid Tool IPFS CID
     * @param delegatee The delegatee address
     * @param parameterName The parameter name (as bytes4(keccak256(name)))
     * @return The parameter value (delegatee-specific or blanket)
     */
    function getPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        bytes4 parameterName
    ) external view returns (bytes memory) {
        // First try delegatee-specific parameter
        bytes memory value = policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName];
        
        // If no delegatee-specific parameter, return blanket parameter
        if (value.length == 0) {
            value = policyParameters[pkpTokenId][toolIpfsCid][address(0)][parameterName];
        }
        
        return value;
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
