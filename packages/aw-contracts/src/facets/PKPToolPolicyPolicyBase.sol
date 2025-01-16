// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyPolicyBase is PKPToolPolicyBase {
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
    ) internal virtual {
        if (bytes(policyIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyPolicyIPFSCID();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Set blanket policy
            tool.blanketPolicy.enabled = true;
            tool.blanketPolicy.ipfsCid = policyIpfsCid;
        } else {
            // Set delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (!policy.enabled) {
                // First time setting policy for this delegatee
                tool.delegateesWithCustomPolicy.push(delegatee);
                tool.delegateeCustomPolicyIndices[delegatee] = tool.delegateesWithCustomPolicy.length;
            }
            policy.enabled = true;
            policy.ipfsCid = policyIpfsCid;
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
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Remove blanket policy
            if (bytes(tool.blanketPolicy.ipfsCid).length == 0) revert PKPToolPolicyErrors.NoPolicySet();
            delete tool.blanketPolicy;
        } else {
            // Remove delegatee-specific policy if it exists
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (policy.enabled) {
                // Remove from delegateesWithCustomPolicy array using index
                uint256 index = tool.delegateeCustomPolicyIndices[delegatee] - 1;
                address[] storage delegatees = tool.delegateesWithCustomPolicy;
                if (index < delegatees.length - 1) {
                    address lastDelegatee = delegatees[delegatees.length - 1];
                    delegatees[index] = lastDelegatee;
                    tool.delegateeCustomPolicyIndices[lastDelegatee] = index + 1;
                }
                delegatees.pop();
                delete tool.delegateeCustomPolicyIndices[delegatee];
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
    ) internal virtual {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Enable blanket policy
            if (bytes(tool.blanketPolicy.ipfsCid).length == 0) revert PKPToolPolicyErrors.NoPolicySet();
            tool.blanketPolicy.enabled = true;
        } else {
            // Enable delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (bytes(policy.ipfsCid).length == 0) revert PKPToolPolicyErrors.NoPolicySet();
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
    ) internal virtual {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Disable blanket policy
            if (bytes(tool.blanketPolicy.ipfsCid).length == 0) revert PKPToolPolicyErrors.NoPolicySet();
            tool.blanketPolicy.enabled = false;
        } else {
            // Disable delegatee-specific policy
            PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
            if (bytes(policy.ipfsCid).length == 0) revert PKPToolPolicyErrors.NoPolicySet();
            policy.enabled = false;
        }
    }
} 