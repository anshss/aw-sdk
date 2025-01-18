// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";

/// @title PKP Tool Policy Base Contract
/// @notice Base contract for managing tool policies in the PKP system
/// @dev Extends PKPToolRegistryBase to provide policy management functionality
/// @custom:security-contact security@litprotocol.com
abstract contract PKPToolRegistryPolicyBase is PKPToolRegistryBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Retrieves the storage layout for the contract
    /// @dev Overrides the base contract's layout function
    /// @return PKPToolRegistryStorage.Layout storage reference to the contract's storage layout
    function _layout() internal pure override returns (PKPToolRegistryStorage.Layout storage) {
        return PKPToolRegistryStorage.layout();
    }

    /// @notice Internal function to set a policy for a tool and delegatee
    /// @dev Sets either a blanket policy or a delegatee-specific policy based on the delegatee address
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (use address(0) for blanket policy)
    /// @param policyIpfsCid The IPFS CID of the policy to set
    /// @param enablePolicy Whether to enable the policy when set
    /// @custom:throws EmptyPolicyIPFSCID if policyIpfsCid is empty
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function _setToolPolicy(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata policyIpfsCid,
        bool enablePolicy
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (bytes(policyIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyPolicyIPFSCID();

        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];
        bytes32 policyIpfsCidHash = keccak256(bytes(policyIpfsCid));

        if (delegatee == address(0)) {
            // Set blanket policy
            PKPToolRegistryStorage.Policy storage blanketPolicy = tool.blanketPolicy[0];
            blanketPolicy.enabled = enablePolicy;
            blanketPolicy.policyIpfsCidHash = policyIpfsCidHash;
            l.hashedPolicyCidToOriginalCid[policyIpfsCidHash] = policyIpfsCid;
        } else {
            // Set delegatee-specific policy
            PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (!tool.delegateesWithCustomPolicy.contains(delegatee)) {
                // First time ever setting policy for this delegatee
                tool.delegateesWithCustomPolicy.add(delegatee);
            }
            policy.enabled = enablePolicy;
            policy.policyIpfsCidHash = policyIpfsCidHash;
            l.hashedPolicyCidToOriginalCid[policyIpfsCidHash] = policyIpfsCid;
        }
    }

    /// @notice Internal function to remove a policy for a tool and delegatee
    /// @dev Removes either a blanket policy or a delegatee-specific policy based on the delegatee address
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (use address(0) for blanket policy)
    /// @custom:throws EmptyIPFSCID if toolIpfsCid is empty
    /// @custom:throws NoPolicySet if attempting to remove a non-existent policy
    function _removeToolPolicy(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Remove blanket policy
            if (tool.blanketPolicy[0].policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            delete tool.blanketPolicy[0];
        } else {
            // Remove delegatee-specific policy if it exists
            PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            tool.delegateesWithCustomPolicy.remove(delegatee);
            delete tool.delegateeCustomPolicies[delegatee];
        }
    }

    /// @notice Internal function to enable a policy
    /// @dev Enables either a blanket policy or a delegatee-specific policy based on the delegatee address
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (use address(0) for blanket policy)
    /// @custom:throws EmptyIPFSCID if toolIpfsCid is empty
    /// @custom:throws NoPolicySet if attempting to enable a non-existent policy
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function _enablePolicy(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Enable blanket policy
            PKPToolRegistryStorage.Policy storage blanketPolicy = tool.blanketPolicy[0];
            if (blanketPolicy.policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            blanketPolicy.enabled = true;
        } else {
            // Enable delegatee-specific policy
            PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            policy.enabled = true;
        }
    }

    /// @notice Internal function to disable a policy
    /// @dev Disables either a blanket policy or a delegatee-specific policy based on the delegatee address
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (use address(0) for blanket policy)
    /// @custom:throws EmptyIPFSCID if toolIpfsCid is empty
    /// @custom:throws NoPolicySet if attempting to disable a non-existent policy
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function _disablePolicy(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Disable blanket policy
            PKPToolRegistryStorage.Policy storage blanketPolicy = tool.blanketPolicy[0];
            if (blanketPolicy.policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            blanketPolicy.enabled = false;
        } else {
            // Disable delegatee-specific policy
            PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.policyIpfsCidHash == bytes32(0)) revert PKPToolRegistryErrors.NoPolicySet();
            policy.enabled = false;
        }
    }
} 