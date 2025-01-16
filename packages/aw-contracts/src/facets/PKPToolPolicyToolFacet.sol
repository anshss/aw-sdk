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
        return l.pkpStore[pkpTokenId].toolMap[toolIpfsCid].isRegistered;
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
        address[] memory allDelegatees = l.pkpDelegatees[pkpTokenId];
        
        uint256 toolsLength = pkpData.toolCids.length;
        uint256 delegateesLength = allDelegatees.length;

        toolIpfsCids = pkpData.toolCids;
        blanketPolicies = new string[](toolsLength);
        delegatees = allDelegatees;
        delegateesPolicies = new string[][](toolsLength);

        // For each tool
        for (uint256 i; i < toolsLength;) {
            string memory toolCid = toolIpfsCids[i];
            PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolCid];
            
            // Get blanket policy
            blanketPolicies[i] = tool.blanketPolicy;
            
            // Initialize policy array for this tool
            delegateesPolicies[i] = new string[](delegateesLength);
            
            // Fill in policies for each delegatee
            for (uint256 j; j < delegateesLength;) {
                delegateesPolicies[i][j] = tool.delegateePolicies[allDelegatees[j]];
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
            if (bytes(tool.blanketPolicy).length > 0 || tool.delegateesWithPolicy.length > 0) {
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
            
            if (bytes(tool.blanketPolicy).length > 0 || tool.delegateesWithPolicy.length > 0) {
                toolsWithPolicy[index] = toolCid;
                delegateesWithPolicy[index] = tool.delegateesWithPolicy;
                hasBlanketPolicy[index] = bytes(tool.blanketPolicy).length > 0;
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
            if (bytes(tool.blanketPolicy).length == 0 && tool.delegateesWithPolicy.length == 0) {
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
            
            if (bytes(tool.blanketPolicy).length == 0 && tool.delegateesWithPolicy.length == 0) {
                toolsWithoutPolicy[index] = toolCid;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    function setTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _setTool(pkpTokenId, toolIpfsCid);
    }

    function removeTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _removeTool(pkpTokenId, toolIpfsCid);
    }

    function setToolBatch(uint256 pkpTokenId, string[] calldata toolIpfsCids) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setTool(pkpTokenId, toolIpfsCids[i]);
            unchecked { ++i; }
        }
    }

    function removeToolBatch(uint256 pkpTokenId, string[] calldata toolIpfsCids) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeTool(pkpTokenId, toolIpfsCids[i]);
            unchecked { ++i; }
        }
    }

    function _setTool(uint256 pkpTokenId, string calldata toolIpfsCid) internal {
        if (bytes(toolIpfsCid).length == 0) {
            revert PKPToolPolicyErrors.EmptyIPFSCID();
        }

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolIpfsCid];

        // If tool already exists, do nothing
        if (tool.isRegistered) {
            return;
        }

        // Add new tool
        tool.isRegistered = true;
        tool.toolCid = toolIpfsCid;
        pkpData.toolCids.push(toolIpfsCid);
        
        emit PKPToolPolicyEvents.ToolRegistered(pkpTokenId, toolIpfsCid);
    }

    function _removeTool(uint256 pkpTokenId, string calldata toolIpfsCid) internal {
        if (bytes(toolIpfsCid).length == 0) {
            revert PKPToolPolicyErrors.EmptyIPFSCID();
        }

        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage tool = pkpData.toolMap[toolIpfsCid];

        // Verify tool exists
        if (!tool.isRegistered) {
            revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
        }

        // Find and remove from toolCids array
        string[] storage tools = pkpData.toolCids;
        for (uint256 i = 0; i < tools.length;) {
            if (keccak256(bytes(tools[i])) == keccak256(bytes(toolIpfsCid))) {
                // Move last element to this position (unless we're already at the end)
                if (i != tools.length - 1) {
                    tools[i] = tools[tools.length - 1];
                }
                tools.pop();
                break;
            }
            unchecked { ++i; }
        }

        // Delete tool info
        delete pkpData.toolMap[toolIpfsCid];
        
        emit PKPToolPolicyEvents.ToolRemoved(pkpTokenId, toolIpfsCid);
    }
} 