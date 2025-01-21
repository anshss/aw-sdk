// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryPolicyParametersBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";
import "../libraries/PKPToolRegistryParameterEvents.sol";
import "./PKPToolRegistryDelegateeFacet.sol";

/// @title PKP Tool Policy Parameter Facet
/// @notice Diamond facet for managing delegatee-specific parameters for PKP tool policies
/// @dev Inherits from PKPToolRegistryParametersBase for common parameter management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryPolicyParameterFacet is PKPToolRegistryPolicyParametersBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Get all registered parameter names and their values for a specific tool and delegatee
    /// @dev Parameters are stored as hashed values but returned as original strings
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for (cannot be zero address)
    /// @return parameterNames Array of registered parameter names in their original string form
    /// @return parameterValues Array of parameter values in bytes form, corresponding to the names
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view verifyToolExists(pkpTokenId, toolIpfsCid) returns (
        string[] memory parameterNames,
        bytes[] memory parameterValues
    ) {
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
        
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        uint256 length = policy.parameterNameHashes.length();
        parameterNames = new string[](length);
        parameterValues = new bytes[](length);
        
        for (uint256 i = 0; i < length;) {
            bytes32 paramNameHash = policy.parameterNameHashes.at(i);
            parameterNames[i] = l.hashedParameterNameToOriginalName[paramNameHash];
            parameterValues[i] = policy.parameters[paramNameHash];
            unchecked { ++i; }
        }
    }

    /// @notice Get a specific parameter value for a tool and delegatee
    /// @dev Returns the raw bytes value that must be interpreted by the caller
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameter for (cannot be zero address)
    /// @param parameterName The name of the parameter to get
    /// @return parameterValue The parameter value in bytes form
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata parameterName
    ) external view verifyToolExists(pkpTokenId, toolIpfsCid) returns (bytes memory parameterValue) {
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
        if (bytes(parameterName).length == 0) revert PKPToolRegistryErrors.InvalidPolicyParameters();
        
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        bytes32 paramNameHash = keccak256(bytes(parameterName));
        return policy.parameters[paramNameHash];
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
    ) external onlyPKPOwner(pkpTokenId) verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
        if (parameterNames.length != parameterValues.length) revert PKPToolRegistryErrors.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 hashedCid = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.Policy storage policy = l.pkpStore[pkpTokenId].toolMap[hashedCid].delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            _setParameter(l, policy, parameterNames[i], parameterValues[i]);
            unchecked { ++i; }
        }

        emit PKPToolRegistryParameterEvents.PolicyParametersSet(
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
    ) external onlyPKPOwner(pkpTokenId) verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
        if (parameterNames.length == 0) revert PKPToolRegistryErrors.InvalidPolicyParameters();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 hashedCid = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.Policy storage policy = l.pkpStore[pkpTokenId].toolMap[hashedCid].delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            _removeParameter(policy, parameterNames[i]);
            unchecked { ++i; }
        }

        emit PKPToolRegistryParameterEvents.PolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterNames
        );
    }
} 