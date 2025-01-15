// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyBase.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";
import "../libraries/PKPToolPolicyEvents.sol";

contract PKPToolPolicyToolFacet is PKPToolPolicyBase {
    using PKPToolPolicyStorage for PKPToolPolicyStorage.Layout;

    struct FilteredToolData {
        string[] allTools;                // All registered tools
        string[] blanketPolicies;         // Blanket policies for each tool (aligned with allTools)
        string[] toolsWithoutPolicy;      // Tools with no policies
        string[] toolsWithPolicy;         // Tools with any policy
        bool[] hasBlanketPolicy;          // Whether each tool with policy has a blanket policy
        address[][] delegateesWithPolicy; // Delegatees for each tool with policy
        string[][] delegateePolicies;     // Policies for each delegatee (aligned with delegateesWithPolicy)
        address[] allDelegatees;          // All delegatees
    }

    function isToolRegistered(uint256 pkpTokenId, string calldata toolIpfsCid) 
        external 
        view 
        returns (bool) 
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        uint256 index = l.toolIndices[pkpTokenId][toolIpfsCid];
        string[] storage tools = l.registeredTools[pkpTokenId];
        
        return index < tools.length && 
            keccak256(bytes(tools[index])) == keccak256(bytes(toolIpfsCid));
    }

    function getRegisteredTools(uint256 pkpTokenId)
        external
        view
        returns (
            string[] memory toolIpfsCids,
            string[][] memory delegateesPolicies,
            address[] memory delegatees,
            string[] memory blanketPolicies
        )
    {
        FilteredToolData memory filtered = _collectToolData(pkpTokenId);
        uint256 toolsLength = filtered.allTools.length;
        uint256 delegateesLength = filtered.allDelegatees.length;

        toolIpfsCids = filtered.allTools;
        blanketPolicies = filtered.blanketPolicies;
        delegatees = filtered.allDelegatees;
        
        // Initialize policy arrays
        delegateesPolicies = new string[][](toolsLength);
        for (uint256 i; i < toolsLength;) {
            delegateesPolicies[i] = new string[](delegateesLength);
            unchecked { ++i; }
        }

        // Fill in policies for tools that have them
        for (uint256 i; i < filtered.toolsWithPolicy.length;) {
            string memory tool = filtered.toolsWithPolicy[i];
            // Find tool's index in allTools
            for (uint256 j; j < toolsLength;) {
                if (keccak256(bytes(filtered.allTools[j])) == keccak256(bytes(tool))) {
                    // For each delegatee with policy
                    for (uint256 k; k < filtered.delegateesWithPolicy[i].length;) {
                        address delegatee = filtered.delegateesWithPolicy[i][k];
                        // Find delegatee's index
                        for (uint256 m; m < delegateesLength;) {
                            if (filtered.allDelegatees[m] == delegatee) {
                                delegateesPolicies[j][m] = filtered.delegateePolicies[i][k];
                                break;
                            }
                            unchecked { ++m; }
                        }
                        unchecked { ++k; }
                    }
                    break;
                }
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
        FilteredToolData memory filtered = _collectToolData(pkpTokenId);
        return (
            filtered.toolsWithPolicy,
            filtered.delegateesWithPolicy,
            filtered.hasBlanketPolicy
        );
    }

    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolsWithoutPolicy)
    {
        FilteredToolData memory filtered = _collectToolData(pkpTokenId);
        return filtered.toolsWithoutPolicy;
    }

    /// @notice Register a tool for a PKP token
    /// @param pkpTokenId The PKP token ID to register the tool for
    /// @param toolIpfsCid The IPFS CID of the tool
    function setTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _setTool(pkpTokenId, toolIpfsCid);
    }

    /// @notice Remove a tool from a PKP token
    /// @param pkpTokenId The PKP token ID to remove the tool from
    /// @param toolIpfsCid The IPFS CID of the tool to remove
    function removeTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _removeTool(pkpTokenId, toolIpfsCid);
    }

    /// @notice Register multiple tools for a PKP token in a single transaction
    /// @param pkpTokenId The PKP token ID to register the tools for
    /// @param toolIpfsCids Array of IPFS CIDs of the tools to register
    function setToolBatch(uint256 pkpTokenId, string[] calldata toolIpfsCids) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _setTool(pkpTokenId, toolIpfsCids[i]);
            unchecked { ++i; }
        }
    }

    /// @notice Remove multiple tools from a PKP token in a single transaction
    /// @param pkpTokenId The PKP token ID to remove the tools from
    /// @param toolIpfsCids Array of IPFS CIDs of the tools to remove
    function removeToolBatch(uint256 pkpTokenId, string[] calldata toolIpfsCids) external onlyPKPOwner(pkpTokenId) {
        for (uint256 i = 0; i < toolIpfsCids.length;) {
            _removeTool(pkpTokenId, toolIpfsCids[i]);
            unchecked { ++i; }
        }
    }

    function _collectToolData(uint256 pkpTokenId)
        internal
        view
        returns (FilteredToolData memory filtered)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        string[] storage allTools = l.registeredTools[pkpTokenId];
        filtered.allDelegatees = l.pkpDelegatees[pkpTokenId];
        uint256 toolsLength = allTools.length;
        uint256 delegateesLength = filtered.allDelegatees.length;

        // Initialize arrays for all tools
        filtered.allTools = new string[](toolsLength);
        filtered.blanketPolicies = new string[](toolsLength);

        // Create max-sized arrays for tools with/without policy
        string[] memory withPolicy = new string[](toolsLength);
        bool[] memory hasBlanket = new bool[](toolsLength);
        address[][] memory delegatees = new address[][](toolsLength);
        string[][] memory policies = new string[][](toolsLength);
        string[] memory withoutPolicy = new string[](toolsLength);
        uint256 withPolicyCount;
        uint256 withoutPolicyCount;
        
        for (uint256 i; i < toolsLength;) {
            string memory tool = allTools[i];
            filtered.allTools[i] = tool;
            
            // Check blanket policy
            string memory blanketPolicy = l.policies[pkpTokenId][tool][address(0)];
            filtered.blanketPolicies[i] = blanketPolicy;
            bool hasBlanketPolicy = bytes(blanketPolicy).length > 0;
            
            // Check delegatee-specific policies
            address[] memory toolDelegatees = new address[](delegateesLength);
            string[] memory toolPolicies = new string[](delegateesLength);
            uint256 delegateeCount;
            
            for (uint256 j; j < delegateesLength;) {
                string memory policy = l.policies[pkpTokenId][tool][filtered.allDelegatees[j]];
                if (bytes(policy).length > 0) {
                    toolDelegatees[delegateeCount] = filtered.allDelegatees[j];
                    toolPolicies[delegateeCount] = policy;
                    unchecked { ++delegateeCount; }
                }
                unchecked { ++j; }
            }
            
            // Resize delegatees and policies arrays to actual size
            if (delegateeCount > 0 || hasBlanketPolicy) {
                address[] memory resizedDelegatees = new address[](delegateeCount);
                string[] memory resizedPolicies = new string[](delegateeCount);
                for (uint256 k; k < delegateeCount;) {
                    resizedDelegatees[k] = toolDelegatees[k];
                    resizedPolicies[k] = toolPolicies[k];
                    unchecked { ++k; }
                }

                withPolicy[withPolicyCount] = tool;
                hasBlanket[withPolicyCount] = hasBlanketPolicy;
                delegatees[withPolicyCount] = resizedDelegatees;
                policies[withPolicyCount] = resizedPolicies;
                unchecked { ++withPolicyCount; }
            } else {
                withoutPolicy[withoutPolicyCount] = tool;
                unchecked { ++withoutPolicyCount; }
            }
            
            unchecked { ++i; }
        }

        // Create correctly sized arrays
        filtered.toolsWithPolicy = new string[](withPolicyCount);
        filtered.hasBlanketPolicy = new bool[](withPolicyCount);
        filtered.delegateesWithPolicy = new address[][](withPolicyCount);
        filtered.delegateePolicies = new string[][](withPolicyCount);
        filtered.toolsWithoutPolicy = new string[](withoutPolicyCount);

        // Copy only the used elements
        for (uint256 i; i < withPolicyCount;) {
            filtered.toolsWithPolicy[i] = withPolicy[i];
            filtered.hasBlanketPolicy[i] = hasBlanket[i];
            filtered.delegateesWithPolicy[i] = delegatees[i];
            filtered.delegateePolicies[i] = policies[i];
            unchecked { ++i; }
        }
        for (uint256 i; i < withoutPolicyCount;) {
            filtered.toolsWithoutPolicy[i] = withoutPolicy[i];
            unchecked { ++i; }
        }
    }

    /// @notice Internal function to register a tool
    /// @param pkpTokenId The PKP token ID to register the tool for
    /// @param toolIpfsCid The IPFS CID of the tool
    function _setTool(uint256 pkpTokenId, string calldata toolIpfsCid) internal {
        if (bytes(toolIpfsCid).length == 0) {
            revert PKPToolPolicyErrors.EmptyIPFSCID();
        }

        PKPToolPolicyStorage.Layout storage layout = _layout();
        uint256 index = layout.toolIndices[pkpTokenId][toolIpfsCid];

        // If index != 0, the tool is already registered at that non-zero index
        if (index != 0) {
            // Already registered => do nothing
            return;
        }

        // If we get here, index == 0, which means either:
        // 1. The tool is not registered at all, or
        // 2. The tool happens to be at index 0 in the array
        string[] storage tools = layout.registeredTools[pkpTokenId];
        if (tools.length > 0) {
            // Check if the tool is actually at index 0
            if (keccak256(bytes(tools[0])) == keccak256(bytes(toolIpfsCid))) {
                // It's at index 0 => do nothing
                return;
            }
        }

        // If we get here, the tool is not registered => add it
        tools.push(toolIpfsCid);
        layout.toolIndices[pkpTokenId][toolIpfsCid] = tools.length - 1;
        emit PKPToolPolicyEvents.ToolRegistered(pkpTokenId, toolIpfsCid);
    }

    /// @notice Internal function to remove a tool
    /// @param pkpTokenId The PKP token ID to remove the tool from
    /// @param toolIpfsCid The IPFS CID of the tool to remove
    function _removeTool(uint256 pkpTokenId, string calldata toolIpfsCid) internal {
        if (bytes(toolIpfsCid).length == 0) {
            revert PKPToolPolicyErrors.EmptyIPFSCID();
        }

        PKPToolPolicyStorage.Layout storage layout = _layout();
        uint256 index = layout.toolIndices[pkpTokenId][toolIpfsCid];
        string[] storage tools = layout.registeredTools[pkpTokenId];

        // First verify the tool exists at the claimed index
        if (index >= tools.length) {
            revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
        }

        // Then verify the tool at that index matches what we're trying to remove
        if (keccak256(bytes(tools[index])) != keccak256(bytes(toolIpfsCid))) {
            revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
        }

        // Get the last element
        uint256 lastIndex = tools.length - 1;
        
        if (index != lastIndex) {
            // If not removing the last element:
            // 1. Get the last tool
            string memory lastTool = tools[lastIndex];
            // 2. Move it to the removed tool's position
            tools[index] = lastTool;
            // 3. Update its index
            layout.toolIndices[pkpTokenId][lastTool] = index;
        }

        // Remove the last element and clean up the index mapping
        tools.pop();
        delete layout.toolIndices[pkpTokenId][toolIpfsCid];
        emit PKPToolPolicyEvents.ToolRemoved(pkpTokenId, toolIpfsCid);
    }
} 