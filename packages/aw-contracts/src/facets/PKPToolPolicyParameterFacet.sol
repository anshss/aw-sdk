// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyParameterFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    /// @notice Get all registered policy parameter names for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get parameters for
    /// @return Array of parameter names registered for this tool and delegatee
    function getToolPolicyParameterNamesForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string[] memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policyNames[pkpTokenId][toolIpfsCid][delegatee];
    }

    /// @notice Get the effective policy parameter value for a tool and delegatee, considering both delegatee-specific and blanket parameters
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameter for
    /// @param parameterName The name of the parameter to get
    /// @return value The effective parameter value (delegatee-specific if set, otherwise blanket parameter)
    /// @return isDelegateeSpecific Whether the returned parameter is delegatee-specific (true) or blanket (false)
    function getEffectiveToolPolicyParameterForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata parameterName
    ) external view returns (bytes memory value, bool isDelegateeSpecific) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        
        // First try delegatee-specific parameter
        value = l.policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName];
        
        if (value.length > 0) {
            return (value, true);
        }

        // If no delegatee-specific parameter, return blanket parameter
        return (l.policyParameters[pkpTokenId][toolIpfsCid][address(0)][parameterName], false);
    }

    /// @notice Get a policy parameter value for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameter for
    /// @param parameterName The name of the parameter to get
    /// @return The parameter value, or empty bytes if not set
    function getToolPolicyParameterForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata parameterName
    ) external view returns (bytes memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName];
    }

    /// @notice Set a policy parameter for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the parameter for
    /// @param parameterName The name of the parameter to set
    /// @param parameterValue The value to set for the parameter
    function setToolPolicyParameterForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata parameterName,
        bytes calldata parameterValue
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();

        _setToolPolicyParameter(pkpTokenId, toolIpfsCid, delegatee, parameterName, parameterValue);
    }

    /// @notice Remove a policy parameter for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address whose parameter should be removed
    /// @param parameterName The name of the parameter to remove
    function removeToolPolicyParameterForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata parameterName
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();

        _removeToolPolicyParameter(pkpTokenId, toolIpfsCid, delegatee, parameterName);
    }

    /// @notice Set multiple parameters for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set parameters for
    /// @param parameterNames Array of parameter names to set
    /// @param parameterValues Array of parameter values to set
    function batchSetToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) external onlyPKPOwner(pkpTokenId) {
        if (parameterNames.length != parameterValues.length) revert PKPToolPolicyErrors.InvalidPolicyParameter();
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        for (uint256 i = 0; i < parameterNames.length;) {
            _setToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                delegatee,
                parameterNames[i],
                parameterValues[i]
            );
            unchecked { ++i; }
        }
    }

    /// @notice Remove multiple parameters for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address whose parameters should be removed
    /// @param parameterNames Array of parameter names to remove
    function batchRemoveToolPolicyParametersForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string[] calldata parameterNames
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        for (uint256 i = 0; i < parameterNames.length;) {
            _removeToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                delegatee,
                parameterNames[i]
            );
            unchecked { ++i; }
        }
    }

    /// @notice Get all registered blanket policy parameter names for a specific tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return Array of parameter names registered for this tool's blanket policy
    function getBlanketToolPolicyParameterNames(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string[] memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policyNames[pkpTokenId][toolIpfsCid][address(0)];
    }

    /// @notice Get a blanket policy parameter value
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to get
    /// @return The parameter value, or empty bytes if not set
    function getBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName
    ) external view returns (bytes memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policyParameters[pkpTokenId][toolIpfsCid][address(0)][parameterName];
    }

    /// @notice Set a parameter for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to set
    /// @param parameterValue The value to set for the parameter
    function setBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName,
        bytes calldata parameterValue
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        _setToolPolicyParameter(pkpTokenId, toolIpfsCid, address(0), parameterName, parameterValue);
    }

    /// @notice Remove a parameter from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterName The name of the parameter to remove
    function removeBlanketToolPolicyParameter(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata parameterName
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        _removeToolPolicyParameter(pkpTokenId, toolIpfsCid, address(0), parameterName);
    }

    /// @notice Set multiple parameters for a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names to set
    /// @param parameterValues Array of parameter values to set
    function batchSetBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames,
        bytes[] calldata parameterValues
    ) external onlyPKPOwner(pkpTokenId) {
        if (parameterNames.length != parameterValues.length) revert PKPToolPolicyErrors.InvalidPolicyParameter();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        for (uint256 i = 0; i < parameterNames.length;) {
            _setToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                address(0),
                parameterNames[i],
                parameterValues[i]
            );
            unchecked { ++i; }
        }
    }

    /// @notice Remove multiple parameters from a blanket policy
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param parameterNames Array of parameter names to remove
    function batchRemoveBlanketToolPolicyParameters(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string[] calldata parameterNames
    ) external onlyPKPOwner(pkpTokenId) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        for (uint256 i = 0; i < parameterNames.length;) {
            _removeToolPolicyParameter(
                pkpTokenId,
                toolIpfsCid,
                address(0),
                parameterNames[i]
            );
            unchecked { ++i; }
        }
    }

    /// @notice Internal function to set a single policy parameter
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the parameter for
    /// @param parameterName The name of the parameter to set
    /// @param parameterValue The value to set for the parameter
    function _setToolPolicyParameter(
        uint256 pkpTokenId,
        string memory toolIpfsCid,
        address delegatee,
        string memory parameterName,
        bytes memory parameterValue
    ) internal {
        if (bytes(parameterName).length == 0) revert PKPToolPolicyErrors.InvalidPolicyParameter();
        if (parameterValue.length == 0) revert PKPToolPolicyErrors.InvalidPolicyParameter();
        _verifyToolRegistered(pkpTokenId, toolIpfsCid);

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        
        // Check if a policy exists for this specific delegatee
        string memory policy = l.policies[pkpTokenId][toolIpfsCid][delegatee];
        if (bytes(policy).length == 0) {
            revert PKPToolPolicyErrors.NoPolicySet();
        }

        l.policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName] = parameterValue;
        _registerPolicyParameterName(pkpTokenId, toolIpfsCid, delegatee, parameterName);

        emit PKPToolPolicyEvents.PolicyParameterSet(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterName,
            parameterValue
        );
    }

    /// @notice Internal function to remove a single policy parameter
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to remove the parameter for
    /// @param parameterName The name of the parameter to remove
    function _removeToolPolicyParameter(
        uint256 pkpTokenId,
        string memory toolIpfsCid,
        address delegatee,
        string memory parameterName
    ) internal {
        if (bytes(parameterName).length == 0) revert PKPToolPolicyErrors.InvalidPolicyParameter();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        delete l.policyParameters[pkpTokenId][toolIpfsCid][delegatee][parameterName];
        
        if (!l.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName]) {
            revert PKPToolPolicyErrors.PolicyParameterNotFound(parameterName);
        }
        
        string[] storage names = l.policyNames[pkpTokenId][toolIpfsCid][delegatee];
        uint256 index = l.policyNameIndices[pkpTokenId][toolIpfsCid][delegatee][parameterName];
        uint256 lastIndex = names.length - 1;
        
        // If not the last element, move last element to this position
        if (index != lastIndex) {
            string memory lastParam = names[lastIndex];
            names[index] = lastParam;
            // Update the index of the moved parameter
            l.policyNameIndices[pkpTokenId][toolIpfsCid][delegatee][lastParam] = index;
        }
        
        // Remove the last element and clear mappings
        names.pop();
        delete l.policyNameIndices[pkpTokenId][toolIpfsCid][delegatee][parameterName];
        l.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName] = false;

        emit PKPToolPolicyEvents.PolicyParameterRemoved(
            pkpTokenId,
            toolIpfsCid,
            delegatee,
            parameterName
        );
    }

    /// @notice Internal function to register a policy parameter name
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address
    /// @param parameterName The name of the parameter to register
    function _registerPolicyParameterName(
        uint256 pkpTokenId,
        string memory toolIpfsCid,
        address delegatee,
        string memory parameterName
    ) internal {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        if (!l.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName]) {
            string[] storage names = l.policyNames[pkpTokenId][toolIpfsCid][delegatee];
            names.push(parameterName);
            l.policyNameIndices[pkpTokenId][toolIpfsCid][delegatee][parameterName] = names.length - 1;
            l.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName] = true;
        }
    }
} 