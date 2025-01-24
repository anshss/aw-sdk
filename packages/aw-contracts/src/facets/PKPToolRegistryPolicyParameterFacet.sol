// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryPolicyParametersBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "./PKPToolRegistryDelegateeFacet.sol";

library LibPKPToolRegistryPolicyParameterFacet {
    error ArrayLengthMismatch();
    error InvalidDelegatee();
    error EmptyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
    error InvalidPolicyParameters();

    event PolicyParametersSet(uint256 indexed pkpTokenId, string toolIpfsCids, address delegatee, string[] parameterNames, bytes[] parameterValues);
    event PolicyParametersRemoved(uint256 indexed pkpTokenId, string toolIpfsCids, address delegatee, string[] parameterNames);
}

/// @title PKP Tool Policy Parameter Facet
/// @notice Diamond facet for managing delegatee-specific parameters for PKP tool policies
/// @dev Inherits from PKPToolRegistryParametersBase for common parameter management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryPolicyParameterFacet is PKPToolRegistryPolicyParametersBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Parameter {
        string name;
        bytes value;
    }

    /// @notice Get specific parameter values for a tool and delegatee
    /// @dev Returns an array of Parameter structs containing names and values
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameters for (cannot be zero address)
    /// @param parameterNames The names of the parameters to get
    /// @return parameters Array of Parameter structs containing names and values
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) external view verifyToolExists(pkpTokenId, toolIpfsCid) returns (Parameter[] memory parameters) {
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyParameterFacet.EmptyIPFSCID();
        if (parameterNames.length == 0) revert LibPKPToolRegistryPolicyParameterFacet.InvalidPolicyParameters();
        
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        // Count how many parameters exist in the set
        uint256 count;
        for (uint256 i = 0; i < parameterNames.length; i++) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            if (policy.parameterNameHashes.contains(paramNameHash)) {
                unchecked { ++count; }
            }
        }
        
        // Initialize array with only existing parameters
        parameters = new Parameter[](count);
        uint256 index;
        for (uint256 i = 0; i < parameterNames.length; i++) {
            bytes32 paramNameHash = keccak256(bytes(parameterNames[i]));
            if (policy.parameterNameHashes.contains(paramNameHash)) {
                parameters[index] = Parameter({
                    name: parameterNames[i],
                    value: policy.parameters[paramNameHash]
                });
                unchecked { ++index; }
            }
        }
    }

    /// @notice Get all registered parameter names and their values for a specific tool and delegatee
    /// @dev Parameters are stored as hashed values but returned as original strings
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for (cannot be zero address)
    /// @return parameters Array of Parameter structs containing names and values
    /// @custom:throws InvalidDelegatee if delegatee is the zero address
    /// @custom:throws ToolNotFound if tool is not registered or enabled
    function getAllToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view verifyToolExists(pkpTokenId, toolIpfsCid) returns (
        Parameter[] memory parameters
    ) {
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyParameterFacet.EmptyIPFSCID();
        
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolCidHash];
        PKPToolRegistryStorage.Policy storage policy = toolInfo.delegateeCustomPolicies[delegatee];
        
        uint256 length = policy.parameterNameHashes.length();
        parameters = new Parameter[](length);
        
        for (uint256 i = 0; i < length;) {
            bytes32 paramNameHash = policy.parameterNameHashes.at(i);
            parameters[i] = Parameter({
                name: l.hashedParameterNameToOriginalName[paramNameHash],
                value: policy.parameters[paramNameHash]
            });
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
    ) external onlyPKPOwner(pkpTokenId) verifyToolExists(pkpTokenId, toolIpfsCid) {
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyParameterFacet.EmptyIPFSCID();
        if (parameterNames.length != parameterValues.length) revert LibPKPToolRegistryPolicyParameterFacet.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 hashedCid = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.Policy storage policy = l.pkpStore[pkpTokenId].toolMap[hashedCid].delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            _setParameter(l, policy, parameterNames[i], parameterValues[i]);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyParameterFacet.PolicyParametersSet(
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
        if (delegatee == address(0)) revert LibPKPToolRegistryPolicyParameterFacet.InvalidDelegatee();
        if (parameterNames.length == 0) revert LibPKPToolRegistryPolicyParameterFacet.InvalidPolicyParameters();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryPolicyParameterFacet.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        bytes32 hashedCid = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.Policy storage policy = l.pkpStore[pkpTokenId].toolMap[hashedCid].delegateeCustomPolicies[delegatee];

        for (uint256 i = 0; i < parameterNames.length;) {
            _removeParameter(policy, parameterNames[i]);
            unchecked { ++i; }
        }

        emit LibPKPToolRegistryPolicyParameterFacet.PolicyParametersRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterNames
        );
    }
} 