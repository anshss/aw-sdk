// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyDelegateeFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    /// @notice Get all delegatees for a PKP
    /// @param pkpTokenId The PKP token ID
    /// @return Array of delegatee addresses
    function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.pkpStore[pkpTokenId].delegatees;
    }

    /// @notice Check if an address is a delegatee of a PKP
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The address to check
    /// @return True if the address is a delegatee
    function isPkpDelegatee(uint256 pkpTokenId, address delegatee) external view returns (bool) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.pkpStore[pkpTokenId].delegateeIndices[delegatee] != 0;
    }

    /// @notice Get all PKPs that have delegated to an address
    /// @param delegatee The delegatee address
    /// @return Array of PKP token IDs
    function getDelegatedPkps(address delegatee) external view returns (uint256[] memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        return delegateeData.delegatedPkps;
    }

    /// @notice Add delegatees to a PKP. For single delegatee operations, pass an array with one element.
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses to add
    function addDelegatees(
        uint256 pkpTokenId,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < delegatees.length;) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolPolicyErrors.ZeroAddressCannotBeDelegatee();
            
            // Add delegatee to PKP's list if not already present
            if (pkpData.delegateeIndices[delegatee] == 0) {
                pkpData.delegatees.push(delegatee);
                pkpData.delegateeIndices[delegatee] = pkpData.delegatees.length;

                // Add PKP to delegatee's list
                PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                delegateeData.delegatedPkps.push(pkpTokenId);
                delegateeData.delegatedPkpIndices[pkpTokenId] = delegateeData.delegatedPkps.length;
            }

            unchecked { ++i; }
        }

        emit PKPToolPolicyDelegateeEvents.AddedDelegatees(pkpTokenId, delegatees);
    }

    /// @notice Remove delegatees from a PKP. For single delegatee operations, pass an array with one element.
    /// @param pkpTokenId The PKP token ID
    /// @param delegatees Array of delegatee addresses to remove
    function removeDelegatees(
        uint256 pkpTokenId,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatees.length == 0) revert PKPToolPolicyErrors.EmptyDelegatees();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < delegatees.length;) {
            address delegatee = delegatees[i];
            if (delegatee == address(0)) revert PKPToolPolicyErrors.ZeroAddressCannotBeDelegatee();

            // Remove delegatee from PKP's list if present
            uint256 delegateeIndex = pkpData.delegateeIndices[delegatee];
            if (delegateeIndex != 0) {
                // Clean up any policies this delegatee had
                _cleanupDelegateePolicies(pkpTokenId, delegatee);

                // Remove from PKP's delegatees array (1-based indexing)
                delegateeIndex--;
                address[] storage pkpDelegatees = pkpData.delegatees;
                if (delegateeIndex < pkpDelegatees.length - 1) {
                    address lastDelegatee = pkpDelegatees[pkpDelegatees.length - 1];
                    pkpDelegatees[delegateeIndex] = lastDelegatee;
                    pkpData.delegateeIndices[lastDelegatee] = delegateeIndex + 1;
                }
                pkpDelegatees.pop();
                delete pkpData.delegateeIndices[delegatee];

                // Remove PKP from delegatee's list
                PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                uint256 pkpIndex = delegateeData.delegatedPkpIndices[pkpTokenId];
                if (pkpIndex != 0) {
                    // Remove from delegatee's PKPs array (1-based indexing)
                    pkpIndex--;
                    uint256[] storage delegatedPkps = delegateeData.delegatedPkps;
                    if (pkpIndex < delegatedPkps.length - 1) {
                        uint256 lastPkp = delegatedPkps[delegatedPkps.length - 1];
                        delegatedPkps[pkpIndex] = lastPkp;
                        delegateeData.delegatedPkpIndices[lastPkp] = pkpIndex + 1;
                    }
                    delegatedPkps.pop();
                    delete delegateeData.delegatedPkpIndices[pkpTokenId];
                }
            }

            unchecked { ++i; }
        }

        emit PKPToolPolicyDelegateeEvents.RemovedDelegatees(pkpTokenId, delegatees);
    }

    /// @notice Internal function to clean up policies when removing a delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The delegatee being removed
    function _cleanupDelegateePolicies(uint256 pkpTokenId, address delegatee) internal {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        string[] storage permittedTools = delegateeData.permittedToolsForPkp[pkpTokenId];

        // Remove all policies for this delegatee's permitted tools
        for (uint256 i = 0; i < permittedTools.length;) {
            string memory toolIpfsCid = permittedTools[i];
            PKPToolPolicyStorage.ToolInfo storage tool = l.pkpStore[pkpTokenId].toolMap[toolIpfsCid];

            // Remove from delegateesWithCustomPolicy if present
            uint256 customPolicyIndex = tool.delegateeCustomPolicyIndices[delegatee];
            if (customPolicyIndex != 0) {
                customPolicyIndex--;
                address[] storage delegateesWithCustomPolicy = tool.delegateesWithCustomPolicy;
                if (customPolicyIndex < delegateesWithCustomPolicy.length - 1) {
                    address lastDelegatee = delegateesWithCustomPolicy[delegateesWithCustomPolicy.length - 1];
                    delegateesWithCustomPolicy[customPolicyIndex] = lastDelegatee;
                    tool.delegateeCustomPolicyIndices[lastDelegatee] = customPolicyIndex + 1;
                }
                delegateesWithCustomPolicy.pop();
                delete tool.delegateeCustomPolicyIndices[delegatee];
            }

            // Delete the policy
            delete tool.delegateeCustomPolicies[delegatee];

            unchecked { ++i; }
        }

        // Clear the permitted tools array and indices
        delete delegateeData.permittedToolsForPkp[pkpTokenId];
    }
} 