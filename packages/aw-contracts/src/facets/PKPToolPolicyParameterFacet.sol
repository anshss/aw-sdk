// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyParametersBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyParameterEvents.sol";

contract PKPToolPolicyParameterFacet is PKPToolPolicyParametersBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get all registered parameter names for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for
    /// @return parameterNames Array of registered parameter names
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
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to remove the parameters for
    /// @param parameterNames The names of the parameters to remove
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