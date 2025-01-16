// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyBlanketParameterFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    /// @notice Get all registered parameter names for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return parameterNames Array of registered parameter names
    function getBlanketToolPolicyParameterNames(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string[] memory) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        return toolInfo.policyParameterNames[address(0)];
    }

    /// @notice Get a specific parameter value from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to get
    /// @return parameterValue The value of the parameter
    function getBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName
    ) external view returns (bytes memory) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        return toolInfo.policyParameters[address(0)][parameterName];
    }

    /// @notice Set a parameter for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to set
    /// @param parameterValue The value to set for the parameter
    function setBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName,
        bytes calldata parameterValue
    ) public onlyPKPOwner(pkpTokenId) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];

        // Register parameter name if not already registered
        string[] storage parameterNames = toolInfo.policyParameterNames[address(0)];
        bool found;
        for (uint256 i; i < parameterNames.length;) {
            if (keccak256(bytes(parameterNames[i])) == keccak256(bytes(parameterName))) {
                found = true;
                break;
            }
            unchecked { ++i; }
        }
        if (!found) {
            parameterNames.push(parameterName);
        }

        // Set parameter value
        toolInfo.policyParameters[address(0)][parameterName] = parameterValue;

        emit PKPToolPolicyEvents.PolicyParameterSet(
            pkpTokenId,
            toolIpfsCid,
            address(0),
            parameterName,
            parameterValue
        );
    }

    /// @notice Remove a parameter from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to remove
    function removeBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName
    ) public onlyPKPOwner(pkpTokenId) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];

        // Remove parameter name
        string[] storage parameterNames = toolInfo.policyParameterNames[address(0)];
        for (uint256 i; i < parameterNames.length;) {
            if (keccak256(bytes(parameterNames[i])) == keccak256(bytes(parameterName))) {
                // Move last element to this position (unless we're already at the end)
                if (i != parameterNames.length - 1) {
                    parameterNames[i] = parameterNames[parameterNames.length - 1];
                }
                parameterNames.pop();
                break;
            }
            unchecked { ++i; }
        }

        // Delete parameter value
        delete toolInfo.policyParameters[address(0)][parameterName];

        emit PKPToolPolicyEvents.PolicyParameterRemoved(
            pkpTokenId,
            toolIpfsCid,
            address(0),
            parameterName
        );
    }

    /// @notice Set multiple parameters for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names to set
    /// @param parameterValues Array of parameter values to set
    function batchSetBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) external onlyPKPOwner(pkpTokenId) {
        if (parameterNames.length != parameterValues.length) {
            revert PKPToolPolicyErrors.ArrayLengthMismatch();
        }

        for (uint256 i; i < parameterNames.length;) {
            setBlanketToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                parameterNames[i],
                parameterValues[i]
            );
            unchecked { ++i; }
        }
    }

    /// @notice Remove multiple parameters from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names to remove
    function batchRemoveBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames
    ) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i; i < parameterNames.length;) {
            removeBlanketToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                parameterNames[i]
            );
            unchecked { ++i; }
        }
    }
} 