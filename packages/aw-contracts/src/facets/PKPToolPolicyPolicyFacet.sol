// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyPolicyFacet is PKPToolPolicyPolicyBase {
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
        PKPToolPolicyStorage.Policy storage delegateePolicy = tool.delegateeCustomPolicies[delegatee];
        if (delegateePolicy.enabled) {
            return (delegateePolicy.ipfsCid, true);
        }

        // If no delegatee-specific policy, return blanket policy
        if (tool.blanketPolicy.enabled) {
            return (tool.blanketPolicy.ipfsCid, false);
        }

        return ("", false);
    }

    /// @notice Get the policy IPFS CID for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The policy IPFS CID for this delegatee, or empty string if not set
    function getCustomToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        return policy.enabled ? policy.ipfsCid : "";
    }

    /// @notice Set policies for specific tools and delegatees
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses to set the policies for
    /// @param policyIpfsCids The array of IPFS CIDs of the policies to set
    function setCustomToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees,
        string[] calldata policyIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length || delegatees.length != policyIpfsCids.length) {
            revert PKPToolPolicyErrors.ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            if (delegatees[i] == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
            _setToolPolicy(pkpTokenId, toolIpfsCids[i], delegatees[i], policyIpfsCids[i]);
            unchecked { ++i; }
        }

        emit PKPToolPolicyPolicyEvents.ToolPoliciesSet(pkpTokenId, toolIpfsCids, delegatees, policyIpfsCids);
    }

    /// @notice Remove delegatee-specific policies for tools
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses whose policies should be removed
    function removeCustomToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            if (delegatees[i] == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
            _removeToolPolicy(pkpTokenId, toolIpfsCids[i], delegatees[i]);
            unchecked { ++i; }
        }

        emit PKPToolPolicyPolicyEvents.ToolPoliciesRemoved(pkpTokenId, toolIpfsCids, delegatees);
    }

    function enableCustomToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            if (delegatees[i] == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
            _enablePolicy(pkpTokenId, toolIpfsCids[i], delegatees[i]);
            unchecked { ++i; }
        }

        emit PKPToolPolicyPolicyEvents.PoliciesEnabled(pkpTokenId, toolIpfsCids, delegatees);
    }

    function disableCustomToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            if (delegatees[i] == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
            _disablePolicy(pkpTokenId, toolIpfsCids[i], delegatees[i]);
            unchecked { ++i; }
        }

        emit PKPToolPolicyPolicyEvents.PoliciesDisabled(pkpTokenId, toolIpfsCids, delegatees);
    }
} 