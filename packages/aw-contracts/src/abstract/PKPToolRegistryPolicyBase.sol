// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";

library LibPKPToolRegistryPolicyBase {
    error EmptyIPFSCID();
    error EmptyPolicyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
    error InvalidDelegatee();
    error PolicyAlreadySet(uint256 pkpTokenId, string toolIpfsCid, address delegatee);
    error NoPolicySet();
    error PolicySameEnabledState(uint256 pkpTokenId, string toolIpfsCid, address delegatee);
}

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
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
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
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyBase.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyBase.EmptyIPFSCID();
        if (bytes(policyIpfsCid).length == 0) revert LibPKPToolRegistryPolicyBase.EmptyPolicyIPFSCID();

        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        if (tool.delegateesWithCustomPolicy.contains(delegatee)) {
            revert LibPKPToolRegistryPolicyBase.PolicyAlreadySet(pkpTokenId, toolIpfsCid, delegatee);
        }

        tool.delegateesWithCustomPolicy.add(delegatee);
        policy.enabled = enablePolicy;
        bytes32 policyIpfsCidHash = keccak256(bytes(policyIpfsCid));
        policy.policyIpfsCidHash = policyIpfsCidHash;
        l.hashedPolicyCidToOriginalCid[policyIpfsCidHash] = policyIpfsCid;
    }

    /// @notice Internal function to remove a policy for a tool and delegatee
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    /// @custom:throws EmptyIPFSCID if toolIpfsCid is empty
    /// @custom:throws NoPolicySet if attempting to remove a non-existent policy
    function _removeToolPolicy(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyBase.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyBase.EmptyIPFSCID();

        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        if (policy.policyIpfsCidHash == bytes32(0)) revert LibPKPToolRegistryPolicyBase.NoPolicySet();
        tool.delegateesWithCustomPolicy.remove(delegatee);
        delete tool.delegateeCustomPolicies[delegatee];
    }

    /// @notice Internal function to set the enabled status of a policy
    /// @param l The storage layout to use
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    /// @param enable Whether to enable or disable the policy
    /// @custom:throws EmptyIPFSCID if toolIpfsCid is empty
    /// @custom:throws NoPolicySet if attempting to modify a non-existent policy
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function _setPolicyEnabled(
        PKPToolRegistryStorage.Layout storage l,
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        bool enable
    ) internal virtual verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyBase.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyBase.EmptyIPFSCID();

        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        if (policy.policyIpfsCidHash == bytes32(0)) revert LibPKPToolRegistryPolicyBase.NoPolicySet();
        if (policy.enabled == enable) revert LibPKPToolRegistryPolicyBase.PolicySameEnabledState(pkpTokenId, toolIpfsCid, delegatee);
        policy.enabled = enable;
    }
} 