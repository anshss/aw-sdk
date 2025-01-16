// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyPolicyFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    /// @notice Get the effective policy IPFS CID for a tool and delegatee, considering both delegatee-specific and blanket policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The effective policy IPFS CID (delegatee-specific if set, otherwise blanket policy)
    /// @return isDelegateeSpecific Whether the returned policy is delegatee-specific (true) or blanket (false)
    function getEffectiveToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid, bool isDelegateeSpecific) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];
        
        // First try delegatee-specific policy
        policyIpfsCid = tool.delegateePolicies[delegatee];
        
        if (bytes(policyIpfsCid).length > 0) {
            return (policyIpfsCid, true);
        }

        // If no delegatee-specific policy, return blanket policy
        return (tool.blanketPolicy, false);
    }

    /// @notice Get the policy IPFS CID for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The policy IPFS CID for this delegatee, or empty string if not set
    function getToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];
        return tool.delegateePolicies[delegatee];
    }

    /// @notice Set a policy for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the policy for
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function setToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata policyIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _setToolPolicy(pkpTokenId, toolIpfsCid, delegatee, policyIpfsCid);
    }

    /// @notice Remove a delegatee-specific policy for a tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address whose policy should be removed
    function removeToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _removeToolPolicy(pkpTokenId, toolIpfsCid, delegatee);
    }

    /// @notice Get the blanket policy IPFS CID for a specific tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return policyIpfsCid The blanket policy IPFS CID, or empty string if not set
    function getBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];
        return tool.blanketPolicy;
    }

    /// @notice Set a blanket policy for a tool (applies when no delegatee-specific policy exists)
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function setBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata policyIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        _setToolPolicy(pkpTokenId, toolIpfsCid, address(0), policyIpfsCid);
    }

    /// @notice Remove a blanket policy for a tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    function removeBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        _removeToolPolicy(pkpTokenId, toolIpfsCid, address(0));
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
    ) internal {
        if (bytes(policyIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyPolicyIPFSCID();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Set blanket policy
            tool.blanketPolicy = policyIpfsCid;
        } else {
            // Set delegatee-specific policy
            if (bytes(tool.delegateePolicies[delegatee]).length == 0) {
                // First time setting policy for this delegatee
                tool.delegateesWithPolicy.push(delegatee);
            }
            tool.delegateePolicies[delegatee] = policyIpfsCid;
        }

        emit PKPToolPolicyEvents.ToolPolicySet(pkpTokenId, toolIpfsCid, delegatee, policyIpfsCid);
    }

    /// @notice Internal function to remove a policy for a tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    function _removeToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

        if (delegatee == address(0)) {
            // Remove blanket policy
            delete tool.blanketPolicy;
        } else {
            // Remove delegatee-specific policy
            if (bytes(tool.delegateePolicies[delegatee]).length > 0) {
                // Remove from delegateesWithPolicy array
                address[] storage delegatees = tool.delegateesWithPolicy;
                for (uint256 i = 0; i < delegatees.length;) {
                    if (delegatees[i] == delegatee) {
                        delegatees[i] = delegatees[delegatees.length - 1];
                        delegatees.pop();
                        break;
                    }
                    unchecked { ++i; }
                }
                delete tool.delegateePolicies[delegatee];
            }
        }

        emit PKPToolPolicyEvents.ToolPolicyRemoved(pkpTokenId, toolIpfsCid, delegatee);
    }
} 