// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryPolicyBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";
import "../libraries/PKPToolRegistryPolicyEvents.sol";

/// @title PKP Tool Registry Policy Facet
/// @notice Diamond facet for managing delegatee-specific policies for PKP tools
/// @dev Inherits from PKPToolRegistryPolicyBase for common policy management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryPolicyFacet is PKPToolRegistryPolicyBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Get the policy IPFS CID for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The policy IPFS CID for this delegatee, or empty string if not set
    /// @return enabled Whether the policy is currently enabled
    function getToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid, bool enabled) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        
        // Check if tool exists
        if (!pkpData.toolCids.contains(toolCidHash)) {
            revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
        }
        
        PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        
        return (l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash], policy.enabled);
    }

    /// @notice Set custom policies for tools and delegatees
    /// @dev Only callable by PKP owner. Arrays must be same length
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    /// @param policyIpfsCids Array of policy IPFS CIDs
    /// @param enablePolicies Whether to enable the policies after setting them
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws EmptyPolicyIPFSCID if any policy CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    function setToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees,
        string[] calldata policyIpfsCids,
        bool enablePolicies
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length || toolIpfsCids.length != policyIpfsCids.length) {
            revert PKPToolRegistryErrors.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setToolPolicy(l, pkpTokenId, toolIpfsCids[i], delegatees[i], policyIpfsCids[i], enablePolicies);
            unchecked { ++i; }
        }

        emit PKPToolRegistryPolicyEvents.ToolPoliciesSet(pkpTokenId, toolIpfsCids, delegatees, policyIpfsCids, enablePolicies);
    }

    /// @notice Remove custom policies for tools and delegatees
    /// @dev Only callable by PKP owner. Arrays must be same length
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    function removeToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) {
            revert PKPToolRegistryErrors.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeToolPolicy(l, pkpTokenId, toolIpfsCids[i], delegatees[i]);
            unchecked { ++i; }
        }

        emit PKPToolRegistryPolicyEvents.ToolPoliciesRemoved(pkpTokenId, toolIpfsCids, delegatees);
    }

    /// @notice Enable custom policies for tools and delegatees
    /// @dev Only callable by PKP owner. Arrays must be same length
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to enable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered
    function enableToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) {
            revert PKPToolRegistryErrors.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setPolicyEnabled(l, pkpTokenId, toolIpfsCids[i], delegatees[i], true);
            unchecked { ++i; }
        }

        emit PKPToolRegistryPolicyEvents.PoliciesEnabled(pkpTokenId, toolIpfsCids, delegatees);
    }

    /// @notice Disable custom policies for tools and delegatees
    /// @dev Only callable by PKP owner. Arrays must be same length
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs
    /// @param delegatees Array of delegatee addresses
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to disable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered
    function disableToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) {
            revert PKPToolRegistryErrors.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setPolicyEnabled(l, pkpTokenId, toolIpfsCids[i], delegatees[i], false);
            unchecked { ++i; }
        }

        emit PKPToolRegistryPolicyEvents.PoliciesDisabled(pkpTokenId, toolIpfsCids, delegatees);
    }
} 