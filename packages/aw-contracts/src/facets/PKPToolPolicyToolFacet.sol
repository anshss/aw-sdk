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
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        string[] storage toolsList = l.registeredTools[pkpTokenId];
        address[] storage delegateesList = l.pkpDelegatees[pkpTokenId];
        uint256 toolsLength = toolsList.length;
        uint256 delegateesLength = delegateesList.length;

        toolIpfsCids = new string[](toolsLength);
        delegateesPolicies = new string[][](toolsLength);
        delegatees = new address[](delegateesLength);
        blanketPolicies = new string[](toolsLength);

        // Copy tools and initialize policy arrays
        for (uint256 i; i < toolsLength;) {
            toolIpfsCids[i] = toolsList[i];
            delegateesPolicies[i] = new string[](delegateesLength);
            blanketPolicies[i] = l.policies[pkpTokenId][toolsList[i]][address(0)];
            unchecked { ++i; }
        }

        // Copy delegatees
        for (uint256 i; i < delegateesLength;) {
            delegatees[i] = delegateesList[i];
            unchecked { ++i; }
        }

        // Fill in delegatee-specific policies
        for (uint256 i; i < toolsLength;) {
            for (uint256 j; j < delegateesLength;) {
                delegateesPolicies[i][j] = l.policies[pkpTokenId][toolsList[i]][delegateesList[j]];
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
        string[] storage allTools = l.registeredTools[pkpTokenId];
        address[] storage allDelegatees = l.pkpDelegatees[pkpTokenId];
        uint256 toolsLength = allTools.length;
        
        // Create a max-sized arrays in memory
        string[] memory tempTools = new string[](toolsLength);
        address[][] memory tempDelegatees = new address[][](toolsLength);
        bool[] memory tempBlanket = new bool[](toolsLength);
        uint256 count;
        
        // Single pass to collect tools with any policies
        for (uint256 i; i < toolsLength;) {
            string storage tool = allTools[i];
            bool hasPolicy = false;
            
            // Check blanket policy
            bool hasBlanket = bytes(l.policies[pkpTokenId][tool][address(0)]).length > 0;
            if (hasBlanket) {
                hasPolicy = true;
            }
            
            // Check delegatee-specific policies
            address[] memory toolDelegatees = new address[](allDelegatees.length);
            uint256 delegateeCount;
            
            for (uint256 j; j < allDelegatees.length;) {
                if (bytes(l.policies[pkpTokenId][tool][allDelegatees[j]]).length > 0) {
                    toolDelegatees[delegateeCount] = allDelegatees[j];
                    unchecked { ++delegateeCount; }
                    hasPolicy = true;
                }
                unchecked { ++j; }
            }
            
            if (hasPolicy) {
                tempTools[count] = tool;
                
                // Resize delegatees array to actual size
                address[] memory resizedDelegatees = new address[](delegateeCount);
                for (uint256 k; k < delegateeCount;) {
                    resizedDelegatees[k] = toolDelegatees[k];
                    unchecked { ++k; }
                }
                tempDelegatees[count] = resizedDelegatees;
                tempBlanket[count] = hasBlanket;
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Create correctly sized arrays and copy only the used elements
        toolsWithPolicy = new string[](count);
        delegateesWithPolicy = new address[][](count);
        hasBlanketPolicy = new bool[](count);
        
        for (uint256 i; i < count;) {
            toolsWithPolicy[i] = tempTools[i];
            delegateesWithPolicy[i] = tempDelegatees[i];
            hasBlanketPolicy[i] = tempBlanket[i];
            unchecked { ++i; }
        }
    }

    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (string[] memory toolsWithoutPolicy)
    {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        string[] storage allTools = l.registeredTools[pkpTokenId];
        address[] storage allDelegatees = l.pkpDelegatees[pkpTokenId];
        uint256 length = allTools.length;
        
        // Create a max-sized array in memory
        string[] memory tempTools = new string[](length);
        uint256 count;
        
        // Single pass to collect tools without any policies
        for (uint256 i; i < length;) {
            string storage tool = allTools[i];
            bool hasPolicy = false;
            
            // Check blanket policy
            if (bytes(l.policies[pkpTokenId][tool][address(0)]).length > 0) {
                hasPolicy = true;
            } else {
                // Check delegatee-specific policies
                for (uint256 j; j < allDelegatees.length && !hasPolicy;) {
                    if (bytes(l.policies[pkpTokenId][tool][allDelegatees[j]]).length > 0) {
                        hasPolicy = true;
                    }
                    unchecked { ++j; }
                }
            }
            
            if (!hasPolicy) {
                tempTools[count] = tool;
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Create correctly sized array and copy only the used elements
        toolsWithoutPolicy = new string[](count);
        for (uint256 i; i < count;) {
            toolsWithoutPolicy[i] = tempTools[i];
            unchecked { ++i; }
        }
    }

    /// @notice Register a tool for a PKP token
    /// @param pkpTokenId The PKP token ID to register the tool for
    /// @param toolIpfsCid The IPFS CID of the tool
    function setTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _setTool(pkpTokenId, toolIpfsCid);
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
    }

    /// @notice Remove a tool from a PKP token
    /// @param pkpTokenId The PKP token ID to remove the tool from
    /// @param toolIpfsCid The IPFS CID of the tool to remove
    function removeTool(uint256 pkpTokenId, string calldata toolIpfsCid) external onlyPKPOwner(pkpTokenId) {
        _removeTool(pkpTokenId, toolIpfsCid);
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
} 