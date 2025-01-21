// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";

/// @title PKP Tool Registry Parameters Base Contract
/// @notice Base contract for managing policy parameters in the PKP tool registry system
/// @dev Extends PKPToolRegistryBase to provide parameter management functionality
/// @custom:security-contact security@litprotocol.com
abstract contract PKPToolRegistryPolicyParametersBase is PKPToolRegistryBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Retrieves the storage layout for the contract
    /// @dev Overrides the base contract's layout function
    /// @return PKPToolRegistryStorage.Layout storage reference to the contract's storage layout
    function _layout() internal pure override returns (PKPToolRegistryStorage.Layout storage) {
        return PKPToolRegistryStorage.layout();
    }

    /// @notice Internal function to set a parameter in a policy
    /// @dev Stores both the parameter value and maintains a set of parameter names
    /// @param l The pre-loaded storage layout
    /// @param policy The policy to set the parameter in
    /// @param parameterName The name of the parameter to set (will be hashed for storage)
    /// @param parameterValue The value to set for the parameter (stored as bytes)
    /// @custom:throws InvalidPolicyParameter if parameter name or value is invalid
    function _setParameter(
        PKPToolRegistryStorage.Layout storage l,
        PKPToolRegistryStorage.Policy storage policy,
        string calldata parameterName,
        bytes calldata parameterValue
    ) internal {
        // Validate parameter name is not empty
        if (bytes(parameterName).length == 0) revert PKPToolRegistryErrors.InvalidPolicyParameters();

        // Validate parameter value is not empty
        if (parameterValue.length == 0) revert PKPToolRegistryErrors.InvalidPolicyValue();

        bytes32 paramNameHash = keccak256(bytes(parameterName));
        
        // Check for duplicate parameter name
        if (policy.parameterNameHashes.contains(paramNameHash)) revert PKPToolRegistryErrors.PolicyParameterAlreadySet(parameterName);
        
        // Store original parameter name in the mapping
        l.hashedParameterNameToOriginalName[paramNameHash] = parameterName;
        
        // Add parameter name to the set if not already present
        policy.parameterNameHashes.add(paramNameHash);
        
        // Store parameter value
        policy.parameters[paramNameHash] = parameterValue;
    }

    /// @notice Internal function to remove a parameter from a policy
    /// @dev Removes both the parameter value and its name from the set
    /// @param policy The policy to remove the parameter from
    /// @param parameterName The name of the parameter to remove (will be hashed)
    /// @custom:throws InvalidPolicyParameter if parameter name is invalid
    function _removeParameter(
        PKPToolRegistryStorage.Policy storage policy,
        string calldata parameterName
    ) internal {
        if (bytes(parameterName).length == 0) revert PKPToolRegistryErrors.InvalidPolicyParameters();

        bytes32 paramNameHash = keccak256(bytes(parameterName));
        // Remove parameter name from the set
        policy.parameterNameHashes.remove(paramNameHash);
        // Delete parameter value
        delete policy.parameters[paramNameHash];
    }
} 