// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PkpToolRegistryPolicyBase.sol";
import "../libraries/PkpToolRegistryStorage.sol";
import "../libraries/PkpToolRegistryErrors.sol";
import "../libraries/PkpToolRegistryPolicyEvents.sol";

/// @title PKP Tool Registry Blanket Policy Facet
/// @notice Diamond facet for managing blanket (default) policies for PKP tools
/// @dev Inherits from PKPToolRegistryPolicyBase for common policy management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryBlanketPolicyFacet is PKPToolRegistryPolicyBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get the blanket policy IPFS CID for a specific tool
    /// @dev Returns empty string if no policy is set or if policy is disabled
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return policyIpfsCid The blanket policy IPFS CID, or empty string if not set/disabled
    function getBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string memory policyIpfsCid) {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = tool.blanketPolicy;
        return policy.enabled ? l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash] : "";
    }

    /// @notice Set blanket policies for multiple tools
    /// @dev Only callable by PKP owner. Sets default policies that apply when no delegatee-specific policy exists
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to set policies for
    /// @param policyIpfsCids Array of policy IPFS CIDs to set as blanket policies
    /// @custom:throws ArrayLengthMismatch if toolIpfsCids and policyIpfsCids arrays have different lengths
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws EmptyPolicyIPFSCID if any policy CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
    function setBlanketToolPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        string[] calldata policyIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != policyIpfsCids.length) revert PKPToolRegistryErrors.ArrayLengthMismatch();

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setToolPolicy(pkpTokenId, toolIpfsCids[i], address(0), policyIpfsCids[i]);
            unchecked { ++i; }
        }
        emit PKPToolRegistryPolicyEvents.BlanketPoliciesSet(pkpTokenId, toolIpfsCids, policyIpfsCids);
    }

    /// @notice Remove blanket policies from multiple tools
    /// @dev Only callable by PKP owner. Removes default policies, falling back to deny-all
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to remove blanket policies from
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to remove a non-existent policy
    function removeBlanketToolPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeToolPolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolRegistryPolicyEvents.BlanketPoliciesRemoved(pkpTokenId, toolIpfsCids);
    }

    /// @notice Enable blanket policies for multiple tools
    /// @dev Only callable by PKP owner. Enables previously set but disabled blanket policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to enable blanket policies for
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to enable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
    function enableBlanketPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _enablePolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolRegistryPolicyEvents.BlanketPoliciesEnabled(pkpTokenId, toolIpfsCids);
    }

    /// @notice Disable blanket policies for multiple tools
    /// @dev Only callable by PKP owner. Temporarily disables blanket policies without removing them
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to disable blanket policies for
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws NoPolicySet if attempting to disable a non-existent policy
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
    function disableBlanketPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _disablePolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolRegistryPolicyEvents.BlanketPoliciesDisabled(pkpTokenId, toolIpfsCids);
    }
} 