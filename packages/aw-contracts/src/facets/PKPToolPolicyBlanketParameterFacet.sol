// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

contract PKPToolPolicyBlanketParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using PKPToolPolicyParameterEvents for *;

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
        return toolInfo.blanketPolicy.parameterNames;
    }

    /// @notice Get specific parameter values from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames The names of the parameters to get
    /// @return parameterValues The values of the parameters
    function getBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames
    ) external view returns (bytes[] memory) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        
        bytes[] memory parameterValues = new bytes[](parameterNames.length);
        for (uint256 i = 0; i < parameterNames.length; i++) {
            parameterValues[i] = toolInfo.blanketPolicy.parameters[parameterNames[i]];
        }
        return parameterValues;
    }

    /// @notice Set parameters for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames The names of the parameters to set
    /// @param parameterValues The values to set for the parameters
    function setBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) public onlyPKPOwner(pkpTokenId) {
        require(parameterNames.length == parameterValues.length, "Mismatched parameter names and values");
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length; i++) {
            _setParameter(policy, parameterNames[i], parameterValues[i]);
        }

        emit PKPToolPolicyParameterEvents.PolicyParametersSet(
            pkpTokenId,
            toolIpfsCid,
            address(0),
            parameterNames,
            parameterValues
        );
    }

    /// @notice Remove parameters from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames The names of the parameters to remove
    function removeBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames
    ) public onlyPKPOwner(pkpTokenId) {
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length; i++) {
            _removeParameter(policy, parameterNames[i]);
        }

        emit PKPToolPolicyParameterEvents.PolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            address(0),
            parameterNames
        );
    }
} 