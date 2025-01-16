// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolRegistryPolicyParametersBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";
import "../libraries/PKPToolRegistryParameterEvents.sol";

/// @title PKP Tool Registry Blanket Parameter Facet
/// @notice Diamond facet for managing blanket (default) parameters for PKP tool registry
/// @dev Inherits from PKPToolRegistryPolicyParametersBase for common parameter management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryBlanketParameterFacet is PKPToolRegistryPolicyParametersBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
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
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        
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
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        
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
        if (parameterNames.length != parameterValues.length) revert PKPToolRegistryErrors.ArrayLengthMismatch();
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            l.hashedParameterNameToOriginalName[paramNameHash] = parameterNames[i];
            policy.parameterNames.add(paramNameHash);
            policy.parameters[paramNameHash] = parameterValues[i];
            unchecked { ++i; }
        }

        emit PKPToolRegistryParameterEvents.BlanketPolicyParametersSet(
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
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.blanketPolicy;

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            policy.parameterNames.remove(paramNameHash);
            delete policy.parameters[paramNameHash];
            unchecked { ++i; }
        }

        emit PKPToolRegistryParameterEvents.BlanketPolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            parameterNames
        );
    }
} 