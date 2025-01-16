// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyParametersBase is PKPToolPolicyBase {
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
        uint256 paramIndex = policy.parameterNameIndices[parameterName];
        if (paramIndex == 0) {
            policy.parameterNames.push(parameterName);
            policy.parameterNameIndices[parameterName] = policy.parameterNames.length;
        }
        policy.parameters[parameterName] = parameterValue;
    }

    /// @notice Internal function to remove a parameter from a policy
    /// @param policy The policy to remove the parameter from
    /// @param parameterName The name of the parameter to remove
    function _removeParameter(
        PKPToolPolicyStorage.Policy storage policy,
        string calldata parameterName
    ) internal {
        uint256 paramIndex = policy.parameterNameIndices[parameterName];
        if (paramIndex != 0) {
            // Convert from 1-based to 0-based indexing
            paramIndex--;
            string[] storage parameterNames = policy.parameterNames;
            
            if (paramIndex < parameterNames.length - 1) {
                string memory lastParam = parameterNames[parameterNames.length - 1];
                parameterNames[paramIndex] = lastParam;
                policy.parameterNameIndices[lastParam] = paramIndex + 1;
            }
            parameterNames.pop();
            delete policy.parameterNameIndices[parameterName];
            delete policy.parameters[parameterName];
        }
    }
} 