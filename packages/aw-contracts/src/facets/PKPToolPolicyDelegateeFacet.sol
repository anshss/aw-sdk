// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyDelegateeFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory) {
        return PKPToolPolicyStorage.layout().pkpDelegatees[pkpTokenId];
    }

    function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool) {
        return PKPToolPolicyStorage.layout().isDelegatee[pkpTokenId][delegatee];
    }

    function getDelegatedPkps(address delegatee) external view returns (uint256[] memory) {
        return PKPToolPolicyStorage.layout().delegateePkps[delegatee];
    }

    function addDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidPKPTokenId();
        
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        if (l.isDelegatee[pkpTokenId][delegatee]) return;

        l.pkpDelegatees[pkpTokenId].push(delegatee);
        l.isDelegatee[pkpTokenId][delegatee] = true;

        l.delegateePkpIndices[delegatee][pkpTokenId] = l.delegateePkps[delegatee].length;
        l.delegateePkps[delegatee].push(pkpTokenId);

        address[] memory singleDelegatee = new address[](1);
        singleDelegatee[0] = delegatee;
        emit PKPToolPolicyEvents.NewDelegatees(pkpTokenId, singleDelegatee);
    }

    function removeDelegatee(uint256 pkpTokenId, address delegatee) external onlyPKPOwner(pkpTokenId) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        if (!l.isDelegatee[pkpTokenId][delegatee]) return;

        // Remove from PKP's delegatees
        address[] storage delegatees = l.pkpDelegatees[pkpTokenId];
        for (uint256 i = 0; i < delegatees.length; i++) {
            if (delegatees[i] == delegatee) {
                delegatees[i] = delegatees[delegatees.length - 1];
                delegatees.pop();
                break;
            }
        }
        l.isDelegatee[pkpTokenId][delegatee] = false;

        // Remove from delegatee's PKPs
        uint256[] storage pkps = l.delegateePkps[delegatee];
        uint256 index = l.delegateePkpIndices[delegatee][pkpTokenId];
        if (index < pkps.length - 1) {
            uint256 lastPkp = pkps[pkps.length - 1];
            pkps[index] = lastPkp;
            l.delegateePkpIndices[delegatee][lastPkp] = index;
        }
        pkps.pop();
        delete l.delegateePkpIndices[delegatee][pkpTokenId];

        emit PKPToolPolicyEvents.DelegateeRemoved(pkpTokenId, delegatee);
    }

    function batchAddDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        for (uint256 i = 0; i < delegatees.length; i++) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidPKPTokenId();
            if (!l.isDelegatee[pkpTokenId][delegatee]) {
                l.pkpDelegatees[pkpTokenId].push(delegatee);
                l.isDelegatee[pkpTokenId][delegatee] = true;
            }
        }

        emit PKPToolPolicyEvents.NewDelegatees(pkpTokenId, delegatees);
    }

    function batchRemoveDelegatees(uint256 pkpTokenId, address[] calldata delegateesToRemove) external onlyPKPOwner(pkpTokenId) {
        if (delegateesToRemove.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        address[] storage delegatees = l.pkpDelegatees[pkpTokenId];
        
        for (uint256 i = 0; i < delegateesToRemove.length; i++) {
            address delegatee = delegateesToRemove[i];
            if (l.isDelegatee[pkpTokenId][delegatee]) {
                for (uint256 j = 0; j < delegatees.length; j++) {
                    if (delegatees[j] == delegatee) {
                        delegatees[j] = delegatees[delegatees.length - 1];
                        delegatees.pop();
                        l.isDelegatee[pkpTokenId][delegatee] = false;
                        emit PKPToolPolicyEvents.DelegateeRemoved(pkpTokenId, delegatee);
                        break;
                    }
                }
            }
        }
    }
} 