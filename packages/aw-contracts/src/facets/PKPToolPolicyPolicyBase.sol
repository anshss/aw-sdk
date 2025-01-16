// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyPolicyBase is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    function _layout() internal pure override returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    /// @notice Internal function to set a policy for a tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function _setToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata policyIpfsCid
    ) internal virtual verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (bytes(policyIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyPolicyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];
        bytes32 policyIpfsCidHash = keccak256(bytes(policyIpfsCid));

        if (delegatee == address(0)) {
            // Set blanket policy
            tool.blanketPolicy.enabled = true;
            tool.blanketPolicy.policyIpfsCidHash = policyIpfsCidHash;
            l.hashedPolicyCidToOriginalCid[policyIpfsCidHash] = policyIpfsCid;
        } else {
            // Set delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (!policy.enabled) {
                // First time setting policy for this delegatee
                tool.delegateesWithCustomPolicy.add(delegatee);
            }
            policy.enabled = true;
            policy.policyIpfsCidHash = policyIpfsCidHash;
            l.hashedPolicyCidToOriginalCid[policyIpfsCidHash] = policyIpfsCid;
        }
    }

    /// @notice Internal function to remove a policy for a tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    function _removeToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Remove blanket policy
            if (tool.blanketPolicy.policyIpfsCidHash == bytes32(0)) revert PKPToolPolicyErrors.NoPolicySet();
            delete tool.blanketPolicy;
        } else {
            // Remove delegatee-specific policy if it exists
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.enabled) {
                tool.delegateesWithCustomPolicy.remove(delegatee);
                delete tool.delegateeCustomPolicies[delegatee];
            }
        }
    }

    /// @notice Internal function to enable a policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    function _enablePolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Enable blanket policy
            if (tool.blanketPolicy.policyIpfsCidHash == bytes32(0)) revert PKPToolPolicyErrors.NoPolicySet();
            tool.blanketPolicy.enabled = true;
        } else {
            // Enable delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.policyIpfsCidHash == bytes32(0)) revert PKPToolPolicyErrors.NoPolicySet();
            policy.enabled = true;
        }
    }

    /// @notice Internal function to disable a policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    function _disablePolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal virtual verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];

        if (delegatee == address(0)) {
            // Disable blanket policy
            if (tool.blanketPolicy.policyIpfsCidHash == bytes32(0)) revert PKPToolPolicyErrors.NoPolicySet();
            tool.blanketPolicy.enabled = false;
        } else {
            // Disable delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.policyIpfsCidHash == bytes32(0)) revert PKPToolPolicyErrors.NoPolicySet();
            policy.enabled = false;
        }
    }
} 