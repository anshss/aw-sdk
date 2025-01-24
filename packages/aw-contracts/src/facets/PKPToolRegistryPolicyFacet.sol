// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryPolicyBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";

library LibPKPToolRegistryPolicyFacet {
    error ArrayLengthMismatch();
    error InvalidDelegatee();
    error EmptyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
    error NoPolicySet(uint256 pkpTokenId, string toolIpfsCid, address delegatee);

    event ToolPoliciesSet(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees, string[] policyIpfsCids, bool enablePolicies);
    event ToolPoliciesRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event PoliciesEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event PoliciesDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
}

/// @title PKP Tool Registry Policy Facet
/// @notice Diamond facet for managing delegatee-specific policies for PKP tools
/// @dev Inherits from PKPToolRegistryPolicyBase for common policy management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryPolicyFacet is PKPToolRegistryPolicyBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ToolPolicy {
        string toolIpfsCid;
        string policyIpfsCid;
        address delegatee;
        bool enabled;
    }

    /// @notice Get the policy IPFS CIDs for specific tools and delegatees
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools
    /// @param delegatees The array of delegatee addresses to get the policies for
    /// @return toolPolicies Array of ToolPolicy structs for each tool and delegatee pair
    function getToolPoliciesForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external view returns (ToolPolicy[] memory toolPolicies) {
        if (toolIpfsCids.length != delegatees.length) revert LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        toolPolicies = new ToolPolicy[](toolIpfsCids.length);

        for (uint256 i = 0; i < toolIpfsCids.length; i++) {
            if (bytes(toolIpfsCids[i]).length == 0) revert LibPKPToolRegistryPolicyFacet.EmptyIPFSCID();
            if (delegatees[i] == address(0)) revert LibPKPToolRegistryPolicyFacet.InvalidDelegatee();

            bytes32 toolCidHash = keccak256(bytes(toolIpfsCids[i]));

            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryPolicyFacet.ToolNotFound(toolIpfsCids[i]);
            }

            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatees[i]];

            toolPolicies[i] = ToolPolicy({
                toolIpfsCid: toolIpfsCids[i],
                policyIpfsCid: l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash],
                delegatee: delegatees[i],
                enabled: policy.enabled
            });
        }

        return toolPolicies;
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
            revert LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setToolPolicy(l, pkpTokenId, toolIpfsCids[i], delegatees[i], policyIpfsCids[i], enablePolicies);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesSet(pkpTokenId, toolIpfsCids, delegatees, policyIpfsCids, enablePolicies);
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
            revert LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeToolPolicy(l, pkpTokenId, toolIpfsCids[i], delegatees[i]);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyFacet.ToolPoliciesRemoved(pkpTokenId, toolIpfsCids, delegatees);
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
            revert LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setPolicyEnabled(l, pkpTokenId, toolIpfsCids[i], delegatees[i], true);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyFacet.PoliciesEnabled(pkpTokenId, toolIpfsCids, delegatees);
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
            revert LibPKPToolRegistryPolicyFacet.ArrayLengthMismatch();
        }

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setPolicyEnabled(l, pkpTokenId, toolIpfsCids[i], delegatees[i], false);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyFacet.PoliciesDisabled(pkpTokenId, toolIpfsCids, delegatees);
    }
} 