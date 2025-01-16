// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyToolFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    function isToolRegistered(uint256 pkpTokenId, string calldata toolIpfsCid) 
        external 
        view 
        returns (bool) 
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.pkpStore[pkpTokenId].toolMap[toolIpfsCid].enabled;
    }

    /// @notice Get all registered tools for a PKP token
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    function getRegisteredTools(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolIpfsCids)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        return pkpData.toolCids;
    }

    /// @notice Get all registered tools and their policies for a PKP token
    /// @param pkpTokenId The PKP token ID
    /// @return toolIpfsCids Array of registered tool IPFS CIDs
    /// @return delegateesPolicies 2D array of policies: [tool][delegatee] -> policy
    /// @return delegatees Array of all delegatees
    /// @return blanketPolicies Array of blanket policies for each tool
    function getRegisteredToolsAndPolicies(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolIpfsCids,
            string[][] memory delegateesPolicies,
            address[] memory delegatees,
            string[] memory blanketPolicies
        )
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 toolsLength = pkpData.toolCids.length;
        uint256 delegateesLength = pkpData.delegatees.length;

        toolIpfsCids = pkpData.toolCids;
        blanketPolicies = new string[](toolsLength);
        delegatees = pkpData.delegatees;
        delegateesPolicies = new string[][](toolsLength);

        // For each tool
        for (uint256 i; i < toolsLength;) {
            string memory toolCid = toolIpfsCids[i];
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCid];
            
            // Get blanket policy
            blanketPolicies[i] = tool.blanketPolicy.ipfsCid;
            
            // Initialize policy array for this tool
            delegateesPolicies[i] = new string[](delegateesLength);
            
            // Fill in policies for each delegatee
            for (uint256 j; j < delegateesLength;) {
                delegateesPolicies[i][j] = tool.delegateeCustomPolicies[delegatees[j]].ipfsCid;
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

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
        uint256 toolsLength = pkpData.toolCids.length;
        
        // Count tools with policies first
        uint256 count;
        for (uint256 i; i < toolsLength;) {
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[pkpData.toolCids[i]];
            if (bytes(tool.blanketPolicy.ipfsCid).length > 0 || tool.delegateesWithCustomPolicy.length > 0) {
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
        for (uint256 i; i < toolsLength;) {
            string memory toolCid = pkpData.toolCids[i];
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCid];
            
            if (bytes(tool.blanketPolicy.ipfsCid).length > 0 || tool.delegateesWithCustomPolicy.length > 0) {
                toolsWithPolicy[index] = toolCid;
                delegateesWithPolicy[index] = tool.delegateesWithCustomPolicy;
                hasBlanketPolicy[index] = bytes(tool.blanketPolicy.ipfsCid).length > 0;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolsWithoutPolicy)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        uint256 toolsLength = pkpData.toolCids.length;
        
        // Count tools without policies first
        uint256 count;
        for (uint256 i; i < toolsLength;) {
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[pkpData.toolCids[i]];
            if (bytes(tool.blanketPolicy.ipfsCid).length == 0 && tool.delegateesWithCustomPolicy.length == 0) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Initialize and fill array
        toolsWithoutPolicy = new string[](count);
        uint256 index;
        for (uint256 i; i < toolsLength;) {
            string memory toolCid = pkpData.toolCids[i];
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCid];
            
            if (bytes(tool.blanketPolicy.ipfsCid).length == 0 && tool.delegateesWithCustomPolicy.length == 0) {
                toolsWithoutPolicy[index] = toolCid;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Register tools for a PKP. For single tool operations, pass an array with one element.
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to register
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

            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolIpfsCid];

            // If tool already exists, revert
            if (tool.enabled) {
                revert PKPToolPolicyErrors.ToolAlreadyExists(toolIpfsCid);
            }

            // Add to tools array if not already present
            if (pkpData.toolCidIndices[toolIpfsCid] == 0) {
                pkpData.toolCids.push(toolIpfsCid);
                pkpData.toolCidIndices[toolIpfsCid] = pkpData.toolCids.length;
            }

            tool.enabled = true;
            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsRegistered(pkpTokenId, toolIpfsCids);
    }

    /// @notice Remove tools from a PKP and update all delegatees' permissions
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to remove
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

            // 1. Remove tool from PKP's tool list using swap-and-pop
            uint256 toolIndex = pkpData.toolCidIndices[toolIpfsCid];
            if (toolIndex == 0) revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);

            // Convert from 1-based to 0-based indexing
            toolIndex--;
            string[] storage tools = pkpData.toolCids;
            if (toolIndex < tools.length - 1) {
                string memory lastTool = tools[tools.length - 1];
                tools[toolIndex] = lastTool;
                pkpData.toolCidIndices[lastTool] = toolIndex + 1;
            }
            tools.pop();
            delete pkpData.toolCidIndices[toolIpfsCid];

            // 2. Update all delegatees' permissions for this tool
            address[] storage delegatees = pkpData.delegatees;
            for (uint256 j = 0; j < delegatees.length;) {
                address delegatee = delegatees[j];
                PKPToolPolicyStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
                
                // Remove tool from delegatee's permitted tools using swap-and-pop
                uint256 permittedIndex = delegateeData.permittedToolIndices[pkpTokenId][toolIpfsCid];
                if (permittedIndex != 0) {
                    // Convert from 1-based to 0-based indexing
                    permittedIndex--;
                    string[] storage permittedTools = delegateeData.permittedToolsForPkp[pkpTokenId];
                    
                    if (permittedIndex < permittedTools.length - 1) {
                        string memory lastPermittedTool = permittedTools[permittedTools.length - 1];
                        permittedTools[permittedIndex] = lastPermittedTool;
                        delegateeData.permittedToolIndices[pkpTokenId][lastPermittedTool] = permittedIndex + 1;
                    }
                    permittedTools.pop();
                    delete delegateeData.permittedToolIndices[pkpTokenId][toolIpfsCid];
                }
                unchecked { ++j; }
            }

            // 3. Delete the tool info and all its policies
            delete pkpData.toolMap[toolIpfsCid];

            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsRemoved(pkpTokenId, toolIpfsCids);
    }

    /// @notice Enable tools for a PKP. For single tool operations, pass an array with one element.
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to enable
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

            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolIpfsCid];
            if (!tool.enabled) revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);

            tool.enabled = true;
            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsEnabled(pkpTokenId, toolIpfsCids);
    }

    /// @notice Disable tools for a PKP. For single tool operations, pass an array with one element.
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids Array of tool IPFS CIDs to disable
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

            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolIpfsCid];
            if (!tool.enabled) revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);

            tool.enabled = false;
            unchecked { ++i; }
        }

        emit PKPToolPolicyToolEvents.ToolsDisabled(pkpTokenId, toolIpfsCids);
    }
} 