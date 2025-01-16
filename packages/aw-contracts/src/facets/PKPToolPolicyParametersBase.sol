// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

/// @title PKP Tool Policy Parameters Base Contract
/// @notice Base contract for managing policy parameters in the PKP tool policy system
/// @dev Extends PKPToolPolicyBase to provide parameter management functionality
/// @custom:security-contact security@litprotocol.com
abstract contract PKPToolPolicyParametersBase is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Retrieves the storage layout for the contract
    /// @dev Overrides the base contract's layout function
    /// @return PKPToolPolicyStorage.Layout storage reference to the contract's storage layout
    function _layout() internal pure override returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    /// @notice Internal function to set a parameter in a policy
    /// @dev Stores both the parameter value and maintains a set of parameter names
    /// @param policy The policy to set the parameter in
    /// @param parameterName The name of the parameter to set (will be hashed for storage)
    /// @param parameterValue The value to set for the parameter (stored as bytes)
    /// @custom:throws InvalidPolicyParameter if parameter name or value is invalid
    function _setParameter(
        PKPToolPolicyStorage.Policy storage policy,
        string calldata parameterName,
        bytes calldata parameterValue
    ) internal {
        bytes32 paramNameHash = keccak256(bytes(parameterName));
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        
        // Store original parameter name in the mapping
        l.hashedParameterNameToOriginalName[paramNameHash] = parameterName;
        
        // Add parameter name to the set if not already present
        policy.parameterNames.add(paramNameHash);
        
        // Store parameter value
        policy.parameters[paramNameHash] = parameterValue;
    }

    /// @notice Internal function to remove a parameter from a policy
    /// @dev Removes both the parameter value and its name from the set
    /// @param policy The policy to remove the parameter from
    /// @param parameterName The name of the parameter to remove (will be hashed)
    /// @custom:throws InvalidPolicyParameter if parameter name is invalid
    function _removeParameter(
        PKPToolPolicyStorage.Policy storage policy,
        string calldata parameterName
    ) internal {
        bytes32 paramNameHash = keccak256(bytes(parameterName));
        
        // Remove parameter name from the set
        policy.parameterNames.remove(paramNameHash);
        
        // Delete parameter value
        delete policy.parameters[paramNameHash];
    }
} 