// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

/// @title PKP Tool Policy Parameter Facet
/// @notice Diamond facet for managing delegatee-specific parameters for PKP tool policies
/// @dev Inherits from PKPToolPolicyParametersBase for common parameter management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolPolicyParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get all registered parameter names for a specific tool and delegatee
    /// @dev Parameters are stored as hashed values but returned as original strings
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for (cannot be zero address)
    /// @return parameterNames Array of registered parameter names in their original string form
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getToolPolicyParameterNamesForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view verifyToolRegistered(pkpTokenId, toolIpfsCid) returns (string[] memory parameterNames) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        uint256 length = policy.parameterNames.length();
        parameterNames = new string[](length);
        for (uint256 i = 0; i < length;) {
            bytes32 paramNameHash = policy.parameterNames.at(i);
            parameterNames[i] = l.hashedParameterNameToOriginalName[paramNameHash];
            unchecked { ++i; }
        }
    }

    /// @notice Get specific parameter values for a delegatee
    /// @dev Returns raw bytes values that must be interpreted by the caller
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameters for (cannot be zero address)
    /// @param parameterNames The names of the parameters to get
    /// @return parameterValues Array of parameter values in bytes form
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) external view verifyToolRegistered(pkpTokenId, toolIpfsCid) returns (bytes[] memory parameterValues) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        parameterValues = new bytes[](parameterNames.length);
        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            parameterValues[i] = policy.parameters[paramNameHash];
            unchecked { ++i; }
        }
    }

    /// @notice Set parameters for a specific tool and delegatee
    /// @dev Only callable by PKP owner. Stores both parameter names and values
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the parameters for (cannot be zero address)
    /// @param parameterNames The names of the parameters to set
    /// @param parameterValues The values to set for the parameters in bytes form
    /// @custom:throws ArrayLengthMismatch if parameterNames and parameterValues arrays have different lengths
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function setToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) public onlyPKPOwner(pkpTokenId) verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (parameterNames.length != parameterValues.length) revert PKPToolPolicyErrors.ArrayLengthMismatch();
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            l.hashedParameterNameToOriginalName[paramNameHash] = parameterNames[i];
            policy.parameterNames.add(paramNameHash);
            policy.parameters[paramNameHash] = parameterValues[i];
            unchecked { ++i; }
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
    /// @dev Only callable by PKP owner. Removes both parameter names and values
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to remove the parameters for (cannot be zero address)
    /// @param parameterNames The names of the parameters to remove
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function removeToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) public onlyPKPOwner(pkpTokenId) verifyToolRegistered(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolPolicyStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            policy.parameterNames.remove(paramNameHash);
            delete policy.parameters[paramNameHash];
            unchecked { ++i; }
        }

        emit PKPToolPolicyParameterEvents.PolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterNames
        );
    }
} 