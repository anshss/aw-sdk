// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyBlanketPolicyFacet is PKPToolPolicyPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get the blanket policy IPFS CID for a specific tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return policyIpfsCid The blanket policy IPFS CID, or empty string if not set
    function getBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = tool.blanketPolicy;
        return policy.enabled ? l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash] : "";
    }

    function setBlanketToolPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        string[] calldata policyIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != policyIpfsCids.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setToolPolicy(pkpTokenId, toolIpfsCids[i], address(0), policyIpfsCids[i]);
            unchecked { ++i; }
        }
        emit PKPToolPolicyEvents.BlanketPoliciesSet(pkpTokenId, toolIpfsCids, policyIpfsCids);
    }

    function removeBlanketToolPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeToolPolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolPolicyEvents.BlanketPoliciesRemoved(pkpTokenId, toolIpfsCids);
    }

    function enableBlanketPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _enablePolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolPolicyEvents.BlanketPoliciesEnabled(pkpTokenId, toolIpfsCids);
    }

    function disableBlanketPolicies(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _disablePolicy(pkpTokenId, toolIpfsCids[i], address(0));
            unchecked { ++i; }
        }
        emit PKPToolPolicyEvents.BlanketPoliciesDisabled(pkpTokenId, toolIpfsCids);
    }
} 