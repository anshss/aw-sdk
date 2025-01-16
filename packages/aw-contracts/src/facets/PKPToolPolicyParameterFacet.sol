// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

contract PKPToolPolicyParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using PKPToolPolicyParameterEvents for *;

    /// @notice Get all registered parameter names for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for
    /// @return parameterNames Array of registered parameter names
    function getToolPolicyParameterNamesForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string[] memory) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        return policy.parameterNames;
    }

    /// @notice Get specific parameter values for a delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameters for
    /// @param parameterNames The names of the parameters to get
    /// @return parameterValues The values of the parameters
    function getToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) external view returns (bytes[] memory) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        bytes[] memory parameterValues = new bytes[](parameterNames.length);
        for (uint256 i = 0; i < parameterNames.length; i++) {
            parameterValues[i] = policy.parameters[parameterNames[i]];
        }
        return parameterValues;
    }

    /// @notice Set parameters for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the parameters for
    /// @param parameterNames The names of the parameters to set
    /// @param parameterValues The values to set for the parameters
    function setToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) public onlyPKPOwner(pkpTokenId) {
        require(parameterNames.length == parameterValues.length, "Mismatched parameter names and values");
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length; i++) {
            _setParameter(policy, parameterNames[i], parameterValues[i]);
        }

        emit PKPToolPolicyParameterEvents.PolicyParametersSet(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterNames,
            parameterValues
        );
    }

    /// @notice Remove parameters for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to remove the parameters for
    /// @param parameterNames The names of the parameters to remove
    function removeToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) public onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length; i++) {
            _removeParameter(policy, parameterNames[i]);
        }

        emit PKPToolPolicyParameterEvents.PolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterNames
        );
    }
} 