// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyParametersBase is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function _layout() internal pure override returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    /// @notice Internal function to set a parameter in a policy
    /// @param policy The policy to set the parameter in
    /// @param parameterName The name of the parameter to set
    /// @param parameterValue The value to set for the parameter
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
    /// @param policy The policy to remove the parameter from
    /// @param parameterName The name of the parameter to remove
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