// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyPolicyFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    /// @notice Get the effective policy IPFS CID for a tool and delegatee, considering both delegatee-specific and blanket policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The effective policy IPFS CID (delegatee-specific if set, otherwise blanket policy)
    /// @return isDelegateeSpecific Whether the returned policy is delegatee-specific (true) or blanket (false)
    function getEffectiveToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid, bool isDelegateeSpecific) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        
        // First try delegatee-specific policy
        policyIpfsCid = l.policies[pkpTokenId][toolIpfsCid][delegatee];
        
        if (bytes(policyIpfsCid).length > 0) {
            return (policyIpfsCid, true);
        }

        // If no delegatee-specific policy, return blanket policy
        return (l.policies[pkpTokenId][toolIpfsCid][address(0)], false);
    }

    /// @notice Get the policy IPFS CID for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the policy for
    /// @return policyIpfsCid The policy IPFS CID for this delegatee, or empty string if not set
    function getToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policies[pkpTokenId][toolIpfsCid][delegatee];
    }

    /// @notice Set a policy for a specific tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to set the policy for
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function setToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata policyIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _setToolPolicy(pkpTokenId, toolIpfsCid, delegatee, policyIpfsCid);
    }

    /// @notice Remove a delegatee-specific policy for a tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address whose policy should be removed
    function removeToolPolicyForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external onlyPKPOwner(pkpTokenId) {
        if (delegatee == address(0)) revert PKPToolPolicyErrors.InvalidDelegatee();
        _removeToolPolicy(pkpTokenId, toolIpfsCid, delegatee);
    }

    /// @notice Get the blanket policy IPFS CID for a specific tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @return policyIpfsCid The blanket policy IPFS CID, or empty string if not set
    function getBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external view returns (string memory policyIpfsCid) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.policies[pkpTokenId][toolIpfsCid][address(0)];
    }

    /// @notice Set a blanket policy for a tool (applies when no delegatee-specific policy exists)
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function setBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        string calldata policyIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        _setToolPolicy(pkpTokenId, toolIpfsCid, address(0), policyIpfsCid);
    }

    /// @notice Remove a blanket policy for a tool
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    function removeBlanketToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid
    ) external onlyPKPOwner(pkpTokenId) {
        _removeToolPolicy(pkpTokenId, toolIpfsCid, address(0));
    }

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
        PKPToolPolicyStorage.Layout storage layout = _layout();
        return layout.policyNames[pkpTokenId][toolIpfsCid][delegatee];
    }

    /// @notice Get the effective policy parameter value for a tool and delegatee, considering both delegatee-specific and blanket parameters
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address to get the parameter for
    /// @param parameterName The name of the parameter to get
    /// @return value The effective parameter value (delegatee-specific if set, otherwise blanket parameter)
    /// @return isDelegateeSpecific Whether the returned parameter is delegatee-specific (true) or blanket (false)
    function getEffectiveToolPolicyParameter(
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

    /// @notice Internal function to set a policy for a tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    /// @param policyIpfsCid The IPFS CID of the policy to set
    function _setToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee,
        string calldata policyIpfsCid
    ) internal {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();
        if (bytes(policyIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyPolicyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        uint256 index = l.toolIndices[pkpTokenId][toolIpfsCid];
        string[] storage tools = l.registeredTools[pkpTokenId];

        // If index != 0, check if it points to our tool
        if (index != 0) {
            if (index >= tools.length || keccak256(bytes(tools[index])) != keccak256(bytes(toolIpfsCid))) {
                revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
            }
        } else {
            // If index == 0, check if it's actually at position 0
            if (tools.length == 0 || keccak256(bytes(tools[0])) != keccak256(bytes(toolIpfsCid))) {
                revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
            }
        }

        l.policies[pkpTokenId][toolIpfsCid][delegatee] = policyIpfsCid;
        emit PKPToolPolicyEvents.ToolPolicySet(pkpTokenId, toolIpfsCid, delegatee, policyIpfsCid);
    }

    /// @notice Internal function to remove a policy for a tool and delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool
    /// @param delegatee The delegatee address (can be address(0) for blanket policy)
    function _removeToolPolicy(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) internal {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        delete l.policies[pkpTokenId][toolIpfsCid][delegatee];

        emit PKPToolPolicyEvents.ToolPolicyRemoved(pkpTokenId, toolIpfsCid, delegatee);
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

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
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
        PKPToolPolicyStorage.Layout storage layout = _layout();
        if (!layout.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName]) {
            layout.policyNames[pkpTokenId][toolIpfsCid][delegatee].push(parameterName);
            layout.isPolicyParameterRegistered[pkpTokenId][toolIpfsCid][delegatee][parameterName] = true;
        }
    }
} 