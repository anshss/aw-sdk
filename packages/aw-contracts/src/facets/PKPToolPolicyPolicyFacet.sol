// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyPolicyEvents.sol";

/// @title PKP Tool Policy Facet
/// @notice Diamond facet for managing delegatee-specific policies for PKP tools
/// @dev Inherits from PKPToolPolicyPolicyBase for common policy management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolPolicyPolicyFacet is PKPToolPolicyPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get the effective policy IPFS CID for a tool and delegatee, considering both delegatee-specific and blanket policies
    /// @dev First checks for a delegatee-specific policy, then falls back to blanket policy if none exists
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The effective policy IPFS CID (delegatee-specific if set, otherwise blanket policy)
    /// @return isDelegateeSpecific Whether the returned policy is delegatee-specific (true) or blanket (false)
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getEffectiveToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid, bool isDelegateeSpecific) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];
        
        // First try delegatee-specific policy
        PKPToolPolicyStorage.Policy storage delegateePolicy = tool.delegateeCustomPolicies[delegatee];
        if (delegateePolicy.enabled) {
            return (l.hashedPolicyCidToOriginalCid[delegateePolicy.policyIpfsCidHash], true);
        }

        // If no delegatee-specific policy, return blanket policy
        if (tool.blanketPolicy.enabled) {
            return (l.hashedPolicyCidToOriginalCid[tool.blanketPolicy.policyIpfsCidHash], false);
        }

        return ("", false);
    }

    /// @notice Get the policy IPFS CID for a specific tool and delegatee
    /// @dev Returns only delegatee-specific policy, ignoring blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The policy IPFS CID for this delegatee, or empty string if not set/disabled
    function getCustomToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[ _hashToolCid(toolIpfsCid)];
        PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        return policy.enabled ? l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash] : "";
    }

    /// @notice Set policies for specific tools and delegatees
    /// @dev Only callable by PKP owner. Sets delegatee-specific policies that override blanket policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses to set the policies for
    /// @param policyIpfsCids The array of IPFS CIDs of the policies to set
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws EmptyPolicyIPFSCID if any policy CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
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
    /// @dev Only callable by PKP owner. Removes custom policies, falling back to blanket policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses whose policies should be removed
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to remove a non-existent policy
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

    /// @notice Enable delegatee-specific policies for tools
    /// @dev Only callable by PKP owner. Enables previously set but disabled custom policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses whose policies should be enabled
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to enable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
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

    /// @notice Disable delegatee-specific policies for tools
    /// @dev Only callable by PKP owner. Temporarily disables custom policies without removing them
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses whose policies should be disabled
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to disable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
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