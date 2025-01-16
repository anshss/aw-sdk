// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

contract PKPToolPolicyBlanketParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get all registered parameter names for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return parameterNames Array of registered parameter names
    function getBlanketToolPolicyParameterNames(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view verifyToolRegistered(pkpTokenId, toolIpfsCid) returns (string[] memory parameterNames) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        
        uint256 length = toolInfo.blanketPolicy.parameterNames.length();
        parameterNames = new string[](length);
        for (uint256 i = 0; i < length;) {
            bytes32 paramNameHash = toolInfo.blanketPolicy.parameterNames.at(i);
            parameterNames[i] = l.hashedParameterNameToOriginalName[paramNameHash];
            unchecked { ++i; }
        }
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
    ) external view verifyToolRegistered(pkpTokenId, toolIpfsCid) returns (bytes[] memory parameterValues) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        
        parameterValues = new bytes[](parameterNames.length);
        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            parameterValues[i] = toolInfo.blanketPolicy.parameters[paramNameHash];
            unchecked { ++i; }
        }
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
    ) public onlyPKPOwner(pkpTokenId) verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (parameterNames.length != parameterValues.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            l.hashedParameterNameToOriginalName[paramNameHash] = parameterNames[i];
            policy.parameterNames.add(paramNameHash);
            policy.parameters[paramNameHash] = parameterValues[i];
            unchecked { ++i; }
        }

        emit PKPToolPolicyParameterEvents.BlanketPolicyParametersSet(
            pkpTokenId,
            toolIpfsCid,
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
    ) public onlyPKPOwner(pkpTokenId) verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            policy.parameterNames.remove(paramNameHash);
            delete policy.parameters[paramNameHash];
            unchecked { ++i; }
        }

        emit PKPToolPolicyParameterEvents.BlanketPolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            parameterNames
        );
    }
} 