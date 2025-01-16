// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

/// @title PKP Tool Policy Blanket Parameter Facet
/// @notice Diamond facet for managing blanket (default) parameters for PKP tool policies
/// @dev Inherits from PKPToolPolicyParametersBase for common parameter management functionality
contract PKPToolPolicyBlanketParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Retrieves all registered parameter names from a tool's blanket policy
    /// @dev Parameters are stored as hashed values but returned as original strings
    /// @param pkpTokenId The ID of the PKP token
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return parameterNames Array of parameter names in their original string form
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

    /// @notice Retrieves specific parameter values from a tool's blanket policy
    /// @dev Returns raw bytes values that must be interpreted by the caller
    /// @param pkpTokenId The ID of the PKP token
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Names of the parameters to retrieve
    /// @return parameterValues Array of parameter values in bytes form
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

    /// @notice Sets parameter values in a tool's blanket policy
    /// @dev Only callable by PKP owner. Stores both parameter names and values
    /// @param pkpTokenId The ID of the PKP token
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Names of the parameters to set
    /// @param parameterValues Values to set for each parameter in bytes form
    /// @custom:throws ArrayLengthMismatch if parameterNames and parameterValues arrays have different lengths
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

    /// @notice Removes parameters from a tool's blanket policy
    /// @dev Only callable by PKP owner. Removes both parameter names and values
    /// @param pkpTokenId The ID of the PKP token
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Names of the parameters to remove
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