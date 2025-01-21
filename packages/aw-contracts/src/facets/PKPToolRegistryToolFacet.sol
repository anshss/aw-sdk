// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "../libraries/PKPToolRegistryErrors.sol";
import "../libraries/PKPToolRegistryToolEvents.sol";

/// @title PKP Tool Policy Tool Management Facet
/// @notice Diamond facet for managing tool registration and lifecycle in the PKP system
/// @dev Inherits from PKPToolPolicyBase for common tool management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryToolFacet is PKPToolRegistryBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Check if a tool is registered and enabled for a PKP
    /// @dev A tool must be both registered and enabled to be usable
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool to check
    /// @return isRegistered True if the tool is registered, false otherwise
    /// @return isEnabled True if the tool is enabled, false otherwise
    function isToolRegistered(uint256 pkpTokenId, string calldata toolIpfsCid) 
        external 
        view 
        returns (bool isRegistered, bool isEnabled) 
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
        
        // Check if tool exists in the set
        isRegistered = pkpData.toolCids.contains(toolCidHash);
        
        // Check if it's enabled
        isEnabled = isRegistered && pkpData.toolMap[toolCidHash].enabled;
    }

    /// @notice Check if a tool is permitted and enabled for a specific delegatee
    /// @dev A tool must be registered, enabled, and the delegatee must have permission to use it
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool to check
    /// @param delegatee The address of the delegatee to check
    /// @return isPermitted True if the tool is permitted for the delegatee, false otherwise
    /// @return isEnabled True if the tool is enabled, false otherwise
    function isToolPermittedForDelegatee(
        uint256 pkpTokenId,
        string calldata toolIpfsCid,
        address delegatee
    ) external view returns (bool isPermitted, bool isEnabled) {
        if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));

        // Check if tool exists
        if (!pkpData.toolCids.contains(toolCidHash)) {
            return (false, false);
        }
        
        // Check if tool is enabled
        PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
        isEnabled = tool.enabled;

        // Check if delegatee has permission
        PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
        isPermitted = delegateeData.permittedToolsForPkp[pkpTokenId].contains(toolCidHash);

        return (isPermitted, isEnabled);
    }

    /// @notice Get all registered tools for a PKP token
    /// @dev Returns all tools regardless of their enabled state
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    function getRegisteredTools(uint256 pkpTokenId)
        public
        view
        returns (string[] memory toolIpfsCids)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = pkpData.toolCids.length();
        toolIpfsCids = new string[](length);
        
        for (uint256 i = 0; i < length;) {
            toolIpfsCids[i] = l.hashedToolCidToOriginalCid[pkpData.toolCids.at(i)];
            unchecked { ++i; }
        }
    }

    /// @notice Get all registered tools and their policies for a PKP token
    /// @dev Returns a comprehensive view of all tools, policies, and delegatees
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    /// @return delegateePolicyCids 2D array of policy IPFS CIDs: [tool][delegatee] -> policyIpfsCid
    /// @return delegatees Array of all delegatees
    function getRegisteredToolsAndPolicies(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolIpfsCids,
            string[][] memory delegateePolicyCids,
            address[] memory delegatees
        )
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        // Get all tool CIDs
        toolIpfsCids = getRegisteredTools(pkpTokenId);
        // Get all delegatees
        delegatees = pkpData.delegatees.values();

        uint256 toolsLength = pkpData.toolCids.length();
        delegateePolicyCids = new string[][](toolsLength);

        uint256 delegateesLength = pkpData.delegatees.length();
        // For each tool
        for (uint256 i = 0; i < toolsLength;) {
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[pkpData.toolCids.at(i)];
            
            // Initialize policy array for this tool
            delegateePolicyCids[i] = new string[](delegateesLength);
            
            // Fill in policies for each delegatee
            for (uint256 j = 0; j < delegateesLength;) {
                PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatees[j]];
                delegateePolicyCids[i][j] = l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash];
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have at least one policy set
    /// @param pkpTokenId The PKP token ID
    /// @return toolsWithPolicy Array of tool IPFS CIDs that have policies
    /// @return delegateesWithPolicy 2D array of delegatee addresses for each tool
    function getToolsWithPolicy(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy
        )
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        uint256 toolsLength = pkpData.toolCids.length();
        
        // Count tools with policies first
        uint256 count;
        for (uint256 i = 0; i < toolsLength;) {
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[pkpData.toolCids.at(i)];
            if (tool.delegateesWithCustomPolicy.length() > 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Initialize arrays
        toolsWithPolicy = new string[](count);
        delegateesWithPolicy = new address[][](count);
        
        // Fill arrays
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (tool.delegateesWithCustomPolicy.length() > 0) {
                toolsWithPolicy[index] = l.hashedToolCidToOriginalCid[toolCidHash];
                
                // Get delegatees with custom policy
                uint256 delegateesLength = tool.delegateesWithCustomPolicy.length();
                delegateesWithPolicy[index] = new address[](delegateesLength);
                for (uint256 j = 0; j < delegateesLength;) {
                    delegateesWithPolicy[index][j] = tool.delegateesWithCustomPolicy.at(j);
                    unchecked { ++j; }
                }
                
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have no policies set
    /// @param pkpTokenId The PKP token ID
    /// @return toolsWithoutPolicy Array of tool IPFS CIDs that have no policies
    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolsWithoutPolicy)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        uint256 toolsLength = pkpData.toolCids.length();
        
        // Count tools without policies first
        uint256 count;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            if (tool.delegateesWithCustomPolicy.length() == 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Initialize and fill array
        toolsWithoutPolicy = new string[](count);
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (tool.delegateesWithCustomPolicy.length() == 0) {
                toolsWithoutPolicy[index] = l.hashedToolCidToOriginalCid[toolCidHash];
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Register tools for a PKP
    /// @dev Only callable by PKP owner. For single tool operations, pass an array with one element
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to register
    /// @custom:throws EmptyIPFSCID if toolIpfsCids array is empty or any CID is empty
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function registerTools(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        bool enabled
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool already exists
            if (pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolAlreadyRegistered(toolIpfsCid);
            }

            // Add to tools set and set enabled state
            l.hashedToolCidToOriginalCid[toolCidHash] = toolIpfsCid;
            pkpData.toolCids.add(toolCidHash);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = enabled;

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsRegistered(pkpTokenId, enabled, toolIpfsCids);
    }

    /// @notice Remove tools from a PKP
    /// @dev Only callable by PKP owner. Removes all policies and delegatee permissions for the tools
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to remove
    /// @custom:throws EmptyIPFSCID if toolIpfsCids array is empty or any CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function removeTools(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
            }

            // Clean up policies and permissions for each delegatees
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            address[] memory pkpDelegatees = pkpData.delegatees.values();
            for (uint256 j = 0; j < pkpDelegatees.length;) {
                address delegatee = pkpDelegatees[j];
                PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

                // Remove the policy if it exists
                if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                    delete tool.delegateeCustomPolicies[delegatee];
                }

                // Remove the tool from permitted tools
                delegateeData.permittedToolsForPkp[pkpTokenId].remove(toolCidHash);
                unchecked { ++j; }
            }

            // Remove tool from set and delete its info
            pkpData.toolCids.remove(toolCidHash);
            delete pkpData.toolMap[toolCidHash];

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsRemoved(pkpTokenId, toolIpfsCids);
    }

    /// @notice Enable tools for a PKP
    /// @dev Only callable by PKP owner. For single tool operations, pass an array with one element
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to enable
    /// @custom:throws EmptyIPFSCID if toolIpfsCids array is empty or any CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function enableTools(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
            }

            // Enable the tool
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = true;

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsEnabled(pkpTokenId, toolIpfsCids);
    }

    /// @notice Disable tools for a PKP
    /// @dev Only callable by PKP owner. For single tool operations, pass an array with one element
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to disable
    /// @custom:throws EmptyIPFSCID if toolIpfsCids array is empty or any CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function disableTools(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
            }

            // Disable the tool
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = false;

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsDisabled(pkpTokenId, toolIpfsCids);
    }

    /// @notice Grant tool permissions to delegatees
    /// @dev Only callable by PKP owner. For single tool/delegatee operations, pass arrays with one element
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools to permit
    /// @param delegatees The array of delegatee addresses to grant permissions to
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered or enabled
    function permitToolsForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) revert PKPToolRegistryErrors.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string calldata toolIpfsCid = toolIpfsCids[i];
            address delegatee = delegatees[i];

            if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
            }

            // Add tool to delegatee's permitted tools
            PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
            delegateeData.permittedToolsForPkp[pkpTokenId].add(toolCidHash);

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsPermitted(pkpTokenId, toolIpfsCids, delegatees);
    }

    /// @notice Remove tool permissions from delegatees
    /// @dev Only callable by PKP owner. For single tool/delegatee operations, pass arrays with one element
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools to unpermit
    /// @param delegatees The array of delegatee addresses to remove permissions from
    /// @custom:throws ArrayLengthMismatch if array lengths don't match
    /// @custom:throws InvalidDelegatee if any delegatee is the zero address
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    /// @custom:throws EmptyIPFSCID if any tool CID is empty
    /// @custom:throws ToolNotFound if any tool is not registered
    function unpermitToolsForDelegatees(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids,
        address[] calldata delegatees
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length != delegatees.length) revert PKPToolRegistryErrors.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string calldata toolIpfsCid = toolIpfsCids[i];
            address delegatee = delegatees[i];

            if (delegatee == address(0)) revert PKPToolRegistryErrors.InvalidDelegatee();
            if (bytes(toolIpfsCid).length == 0) revert PKPToolRegistryErrors.EmptyIPFSCID();

            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolRegistryErrors.ToolNotFound(toolIpfsCid);
            }

            // Clean up policies and permissions
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

            // Remove the policy if it exists
            if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                delete tool.delegateeCustomPolicies[delegatee];
            }

            // Remove the tool from permitted tools
            delegateeData.permittedToolsForPkp[pkpTokenId].remove(toolCidHash);

            unchecked { ++i; }
        }

        emit PKPToolRegistryToolEvents.ToolsUnpermitted(pkpTokenId, toolIpfsCids, delegatees);
    }
} 