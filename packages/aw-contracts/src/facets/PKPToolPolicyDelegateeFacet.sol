// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyDelegateeFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory) {
        return PKPToolPolicyStorage.layout().pkpStore[pkpTokenId].delegatees;
    }

    function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool) {
        return PKPToolPolicyStorage.layout().pkpStore[pkpTokenId].delegateeIndices[delegatee] != 0;
    }

    function getDelegatedPkps(address delegatee) external view returns (uint256[] memory) {
        return PKPToolPolicyStorage.layout().delegatees[delegatee].delegatedPkps;
    }

    function addDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        _addDelegatee(pkpTokenId, delegatee);
        emit PKPToolPolicyEvents.AddedDelegatee(pkpTokenId, delegatee);
    }

    function removeDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        _removeDelegatee(pkpTokenId, delegatee);
        emit PKPToolPolicyEvents.RemovedDelegatee(pkpTokenId, delegatee);
    }

    function batchAddDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        for (uint256 i = 0; i < delegatees.length; i++) {
            address delegatee = delegatees[i];
            _addDelegatee(pkpTokenId, delegatee);
        }

        emit PKPToolPolicyEvents.BatchAddedDelegatees(pkpTokenId, delegatees);
    }

    function batchRemoveDelegatees(uint256 pkpTokenId, address[] calldata delegateesToRemove) external onlyPKPOwner(pkpTokenId) {
        if (delegateesToRemove.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        for (uint256 i = 0; i < delegateesToRemove.length; i++) {
            address delegatee = delegateesToRemove[i];
            _removeDelegatee(pkpTokenId, delegatee);
        }

        emit PKPToolPolicyEvents.BatchRemovedDelegatees(pkpTokenId, delegateesToRemove);
    }

    /// @notice Internal function to add a delegatee to a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee address to add
    function _addDelegatee(uint256 pkpTokenId, address delegatee) internal {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.ZeroAddressCannotBeDelegatee();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

        if (pkpData.delegateeIndices[delegatee] != 0) revert PKPToolPolicyErrors.DelegateeAlreadyExists(pkpTokenId, delegatee);

        pkpData.delegatees.push(delegatee);
        pkpData.delegateeIndices[delegatee] = pkpData.delegatees.length;

        delegateeData.delegatedPkps.push(pkpTokenId);
        delegateeData.delegatedPkpIndices[pkpTokenId] = delegateeData.delegatedPkps.length;
    }

    /// @notice Internal function to remove a delegatee from a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee address to remove
    function _removeDelegatee(uint256 pkpTokenId, address delegatee) internal {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        if (pkpData.delegateeIndices[delegatee] == 0) revert PKPToolPolicyErrors.DelegateeNotFound(pkpTokenId, delegatee);

        PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

        // Clean up tool policies for this delegatee
        _cleanupDelegateePolicies(pkpTokenId, delegatee);

        // Remove from PKP's delegatees
        uint256 index = pkpData.delegateeIndices[delegatee] - 1;
        address[] storage delegatees = pkpData.delegatees;
        if (index < delegatees.length - 1) {
            address lastDelegatee = delegatees[delegatees.length - 1];
            delegatees[index] = lastDelegatee;
            pkpData.delegateeIndices[lastDelegatee] = index + 1;
        }
        delegatees.pop();
        delete pkpData.delegateeIndices[delegatee];

        // Remove from delegatee's PKPs
        uint256 pkpIndex = delegateeData.delegatedPkpIndices[pkpTokenId] - 1;
        uint256[] storage pkps = delegateeData.delegatedPkps;
        if (pkpIndex < pkps.length - 1) {
            uint256 lastPkp = pkps[pkps.length - 1];
            pkps[pkpIndex] = lastPkp;
            delegateeData.delegatedPkpIndices[lastPkp] = pkpIndex + 1;
        }
        pkps.pop();
        delete delegateeData.delegatedPkpIndices[pkpTokenId];
    }

    /// @notice Internal function to clean up all tool policies for a delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee address to clean up
    function _cleanupDelegateePolicies(uint256 pkpTokenId, address delegatee) internal {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

        // Get the list of tools this delegatee has permissions for
        string[] storage permittedTools = delegateeData.permittedToolsForPkp[pkpTokenId];
        for (uint256 i = 0; i < permittedTools.length; i++) {
            string memory toolCid = permittedTools[i];
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCid];

            // Remove from delegateesWithCustomPolicy array
            uint256 index = tool.delegateeCustomPolicyIndices[delegatee] - 1;
            address[] storage delegatees = tool.delegateesWithCustomPolicy;
            if (index < delegatees.length - 1) {
                address lastDelegatee = delegatees[delegatees.length - 1];
                delegatees[index] = lastDelegatee;
                tool.delegateeCustomPolicyIndices[lastDelegatee] = index + 1;
            }
            delegatees.pop();
            delete tool.delegateeCustomPolicyIndices[delegatee];

            // Clear policy
            delete tool.delegateeCustomPolicies[delegatee];
        }

        // Clear the permitted tools array
        delete delegateeData.permittedToolsForPkp[pkpTokenId];
    }
} 