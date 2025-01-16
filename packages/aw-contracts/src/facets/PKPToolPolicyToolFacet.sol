// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyToolEvents.sol";

/// @title PKP Tool Policy Tool Management Facet
/// @notice Diamond facet for managing tool registration and lifecycle in the PKP system
/// @dev Inherits from PKPToolPolicyBase for common tool management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolPolicyToolFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice Check if a tool is registered and enabled for a PKP
    /// @dev A tool must be both registered and enabled to be usable
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool to check
    /// @return bool True if the tool is registered and enabled, false otherwise
    function isToolRegistered(uint256 pkpTokenId, string calldata toolIpfsCid) 
        external 
        view 
        returns (bool) 
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.pkpStore[pkpTokenId].toolMap[_hashToolCid(toolIpfsCid)].enabled;
    }

    /// @notice Get all registered tools for a PKP token
    /// @dev Returns all tools regardless of their enabled state
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    function getRegisteredTools(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolIpfsCids)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = pkpData.toolCids.length();
        toolIpfsCids = new string[](length);
        
        for (uint256 i = 0; i < length;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            toolIpfsCids[i] = _getOriginalToolCid(toolCidHash);
            unchecked { ++i; }
        }
    }

    /// @notice Get all registered tools and their policies for a PKP token
    /// @dev Returns a comprehensive view of all tools, policies, and delegatees
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    /// @return delegateePolicyCids 2D array of policy IPFS CIDs: [tool][delegatee] -> policyIpfsCid
    /// @return delegatees Array of all delegatees
    /// @return blanketPolicyCids Array of blanket policy IPFS CIDs for each tool
    function getRegisteredToolsAndPolicies(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolIpfsCids,
            string[][] memory delegateePolicyCids,
            address[] memory delegatees,
            string[] memory blanketPolicyCids
        )
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 toolsLength = pkpData.toolCids.length();
        uint256 delegateesLength = pkpData.delegatees.length();

        // Get all tool CIDs
        toolIpfsCids = new string[](toolsLength);
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            toolIpfsCids[i] = _getOriginalToolCid(toolCidHash);
            unchecked { ++i; }
        }

        // Get all delegatees
        delegatees = new address[](delegateesLength);
        for (uint256 i = 0; i < delegateesLength;) {
            delegatees[i] = pkpData.delegatees.at(i);
            unchecked { ++i; }
        }

        blanketPolicyCids = new string[](toolsLength);
        delegateePolicyCids = new string[][](toolsLength);

        // For each tool
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            // Get blanket policy CID
            if (tool.blanketPolicy.enabled) {
                blanketPolicyCids[i] = l.hashedPolicyCidToOriginalCid[tool.blanketPolicy.policyIpfsCidHash];
            }
            
            // Initialize policy array for this tool
            delegateePolicyCids[i] = new string[](delegateesLength);
            
            // Fill in policies for each delegatee
            for (uint256 j = 0; j < delegateesLength;) {
                PKPToolPolicyStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatees[j]];
                if (policy.enabled) {
                    delegateePolicyCids[i][j] = l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash];
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have at least one policy set
    /// @dev Returns tools with either blanket policies or delegatee-specific policies
    /// @param pkpTokenId The PKP token ID
    /// @return toolsWithPolicy Array of tool IPFS CIDs that have policies
    /// @return delegateesWithPolicy 2D array of delegatee addresses for each tool
    /// @return hasBlanketPolicy Array indicating if each tool has a blanket policy
    function getToolsWithPolicy(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolsWithPolicy,
            address[][] memory delegateesWithPolicy,
            bool[] memory hasBlanketPolicy
        )
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        uint256 toolsLength = pkpData.toolCids.length();
        
        // Count tools with policies first
        uint256 count;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            if (tool.blanketPolicy.enabled || tool.delegateesWithCustomPolicy.length() > 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Initialize arrays
        toolsWithPolicy = new string[](count);
        delegateesWithPolicy = new address[][](count);
        hasBlanketPolicy = new bool[](count);
        
        // Fill arrays
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (tool.blanketPolicy.enabled || tool.delegateesWithCustomPolicy.length() > 0) {
                toolsWithPolicy[index] = _getOriginalToolCid(toolCidHash);
                
                // Get delegatees with custom policy
                uint256 delegateesLength = tool.delegateesWithCustomPolicy.length();
                delegateesWithPolicy[index] = new address[](delegateesLength);
                for (uint256 j = 0; j < delegateesLength;) {
                    delegateesWithPolicy[index][j] = tool.delegateesWithCustomPolicy.at(j);
                    unchecked { ++j; }
                }
                
                hasBlanketPolicy[index] = tool.blanketPolicy.enabled;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have no policies set
    /// @dev Returns tools that have neither blanket policies nor delegatee-specific policies
    /// @param pkpTokenId The PKP token ID
    /// @return toolsWithoutPolicy Array of tool IPFS CIDs that have no policies
    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolsWithoutPolicy)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        uint256 toolsLength = pkpData.toolCids.length();
        
        // Count tools without policies first
        uint256 count;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            if (!tool.blanketPolicy.enabled && tool.delegateesWithCustomPolicy.length() == 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Initialize and fill array
        toolsWithoutPolicy = new string[](count);
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (!tool.blanketPolicy.enabled && tool.delegateesWithCustomPolicy.length() == 0) {
                toolsWithoutPolicy[index] = _getOriginalToolCid(toolCidHash);
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
    /// @custom:throws ToolAlreadyExists if any tool is already registered
    /// @custom:throws NotPKPOwner if caller is not the PKP owner
    function registerTools(
        uint256 pkpTokenId,
        string[] calldata toolIpfsCids
    ) external onlyPKPOwner(pkpTokenId) {
        if (toolIpfsCids.length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

            bytes32 toolCidHash = _storeToolCid(toolIpfsCid);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];

            // If tool already exists, revert
            if (tool.enabled) {
                revert PKPToolPolicyErrors.ToolAlreadyExists(toolIpfsCid);
            }

            // Add to tools set if not already present
            if (pkpData.toolCids.add(toolCidHash)) {
                tool.enabled = true;
            }

            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsRegistered(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

            bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
            }

            // 1. Remove tool from PKP's tool set
            pkpData.toolCids.remove(toolCidHash);

            // 2. Update all delegatees' permissions for this tool
            uint256 delegateesLength = pkpData.delegatees.length();
            for (uint256 j = 0; j < delegateesLength;) {
                address delegatee = pkpData.delegatees.at(j);
                PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                
                // Remove tool from delegatee's permitted tools
                delegateeData.permittedToolsForPkp[pkpTokenId].remove(toolCidHash);
                unchecked { ++j; }
            }

            // 3. Delete the tool info and all its policies
            delete pkpData.toolMap[toolCidHash];

            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsRemoved(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

            bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            if (!tool.enabled) revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);

            tool.enabled = true;
            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsEnabled(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

            bytes32 toolCidHash = _hashToolCid(toolIpfsCid);
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            if (!tool.enabled) revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);

            tool.enabled = false;
            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsDisabled(pkpTokenId, toolIpfsCids);
    }
} 