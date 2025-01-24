// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../abstract/PKPToolRegistryBase.sol";
import "../libraries/PKPToolRegistryStorage.sol";

library LibPKPToolRegistryToolFacet {
    error InvalidDelegatee();
    error EmptyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
    error ToolAlreadyRegistered(string toolIpfsCid);
    error ArrayLengthMismatch();

    event ToolsRegistered(uint256 indexed pkpTokenId, bool enabled, string[] toolIpfsCids);
    event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids);
    event ToolsPermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
    event ToolsUnpermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees);
}

/// @title PKP Tool Policy Tool Management Facet
/// @notice Diamond facet for managing tool registration and lifecycle in the PKP system
/// @dev Inherits from PKPToolPolicyBase for common tool management functionality
/// @custom:security-contact security@litprotocol.com
contract PKPToolRegistryToolFacet is PKPToolRegistryBase {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct ToolInfo {
        string toolIpfsCid;
        bool toolEnabled;
    }

    struct ToolInfoWithDelegateePolicy {
        string toolIpfsCid;
        bool toolEnabled;
        address delegatee;
        string policyIpfsCid;
        bool policyEnabled;
    }

    struct ToolInfoWithDelegateesAndPolicies {
        string toolIpfsCid;
        bool toolEnabled;
        address[] delegatees;
        string[] delegateesPolicyIpfsCids;
        bool[] delegateesPolicyEnabled;
    }

    struct ToolInfoWithDelegatees {
        string toolIpfsCid;
        bool toolEnabled;
        address[] delegatees;
    }

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
        if (delegatee == address(0)) revert LibPKPToolRegistryToolFacet.InvalidDelegatee();
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

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

    /// @notice Get specific registered tools for a PKP token
    /// @dev Returns an array of ToolInfo structs containing tool IPFS CIDs and their enabled state
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids An array of IPFS CIDs of the tools to retrieve
    /// @return toolsInfo Array of ToolInfo structs containing tool details
    function getRegisteredTools(uint256 pkpTokenId, string[] calldata toolIpfsCids)
        external
        view
        returns (ToolInfo[] memory toolsInfo)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = toolIpfsCids.length;
        toolsInfo = new ToolInfo[](length);
        
        for (uint256 i = 0; i < length;) {
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCids[i]));

            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCids[i]);
            }

            // Retrieve tool information
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            toolsInfo[i] = ToolInfo({
                toolIpfsCid: l.hashedToolCidToOriginalCid[toolCidHash],
                toolEnabled: tool.enabled
            });
            unchecked { ++i; }
        }
    }

    /// @notice Get all registered tools for a PKP token
    /// @dev Returns an array of ToolInfo structs containing tool IPFS CIDs and their enabled state
    /// @param pkpTokenId The PKP token ID
    /// @return toolsInfo Array of ToolInfo structs
    function getAllRegisteredTools(uint256 pkpTokenId)
        public
        view
        returns (ToolInfo[] memory toolsInfo)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = pkpData.toolCids.length();
        toolsInfo = new ToolInfo[](length);
        
        for (uint256 i = 0; i < length;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            toolsInfo[i] = ToolInfo({
                toolIpfsCid: l.hashedToolCidToOriginalCid[toolCidHash],
                toolEnabled: pkpData.toolMap[toolCidHash].enabled
            });
            unchecked { ++i; }
        }
    }

    /// @notice Get registered tools and their delegatees for a PKP token
    /// @dev Returns an array of ToolInfoWithDelegateesAndPolicies structs containing tool IPFS CIDs, their enabled state, and delegatees with their policies
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCids The array of IPFS CIDs of the tools to retrieve
    /// @return toolsInfo Array of ToolInfoWithDelegateesAndPolicies structs containing tool and delegatee details
    function getRegisteredToolsAndDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids)
        external
        view
        returns (ToolInfoWithDelegateesAndPolicies[] memory toolsInfo)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        
        uint256 length = toolIpfsCids.length;
        toolsInfo = new ToolInfoWithDelegateesAndPolicies[](length);

        for (uint256 i = 0; i < length;) {
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCids[i]));

            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCids[i]);
            }

            // Retrieve tool information
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            ToolInfoWithDelegateesAndPolicies memory toolInfo;
            toolInfo.toolIpfsCid = l.hashedToolCidToOriginalCid[toolCidHash];
            toolInfo.toolEnabled = tool.enabled;

            // Get delegatees with custom policy
            uint256 delegateesWithPolicyLength = tool.delegateesWithCustomPolicy.length();
            toolInfo.delegatees = new address[](delegateesWithPolicyLength);
            toolInfo.delegateesPolicyIpfsCids = new string[](delegateesWithPolicyLength);
            toolInfo.delegateesPolicyEnabled = new bool[](delegateesWithPolicyLength);

            // Fill in policies for each delegatee that has a custom policy
            for (uint256 j = 0; j < delegateesWithPolicyLength;) {
                address delegatee = tool.delegateesWithCustomPolicy.at(j);
                PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
                toolInfo.delegatees[j] = delegatee;
                toolInfo.delegateesPolicyIpfsCids[j] = l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash];
                toolInfo.delegateesPolicyEnabled[j] = policy.enabled;
                unchecked { ++j; }
            }

            toolsInfo[i] = toolInfo;
            unchecked { ++i; }
        }
    }

    /// @notice Get all registered tools and their policies for a PKP token
    /// @dev Returns a comprehensive view of all tools, policies, and delegatees
    /// @param pkpTokenId The PKP token ID
    /// @return toolsInfo Array of ToolPolicyInfo structs containing tool and policy details
    function getAllRegisteredToolsAndDelegatees(uint256 pkpTokenId)
        external
        view
        returns (ToolInfoWithDelegateesAndPolicies[] memory toolsInfo)
    {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        uint256 toolsLength = pkpData.toolCids.length();
        toolsInfo = new ToolInfoWithDelegateesAndPolicies[](toolsLength);

        // For each tool
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];

            // Initialize ToolInfoWithDelegatees struct
            ToolInfoWithDelegateesAndPolicies memory toolInfo;
            toolInfo.toolIpfsCid = l.hashedToolCidToOriginalCid[toolCidHash];
            toolInfo.toolEnabled = tool.enabled;

            // Get delegatees with custom policy
            uint256 delegateesWithPolicyLength = tool.delegateesWithCustomPolicy.length();
            toolInfo.delegatees = new address[](delegateesWithPolicyLength);
            toolInfo.delegateesPolicyIpfsCids = new string[](delegateesWithPolicyLength);
            toolInfo.delegateesPolicyEnabled = new bool[](delegateesWithPolicyLength);

            // Fill in policies for each delegatee that has a custom policy
            for (uint256 j = 0; j < delegateesWithPolicyLength;) {
                address delegatee = tool.delegateesWithCustomPolicy.at(j);
                PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
                toolInfo.delegatees[j] = delegatee;
                toolInfo.delegateesPolicyIpfsCids[j] = l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash];
                toolInfo.delegateesPolicyEnabled[j] = policy.enabled;
                unchecked { ++j; }
            }

            toolsInfo[i] = toolInfo;
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have at least one policy set
    /// @param pkpTokenId The PKP token ID
    /// @return toolsInfo Array of ToolInfoWithDelegatees structs containing tool and policy details
    function getToolsWithPolicy(uint256 pkpTokenId)
        external
        view
        returns (ToolInfoWithDelegateesAndPolicies[] memory toolsInfo)
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
        
        // Initialize array of ToolInfoWithDelegatees
        toolsInfo = new ToolInfoWithDelegateesAndPolicies[](count);
        
        // Fill array with ToolInfoWithDelegatees structs
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (tool.delegateesWithCustomPolicy.length() > 0) {
                ToolInfoWithDelegateesAndPolicies memory toolInfo;
                toolInfo.toolIpfsCid = l.hashedToolCidToOriginalCid[toolCidHash];
                toolInfo.toolEnabled = tool.enabled;
                
                // Get delegatees with custom policy
                uint256 delegateesLength = tool.delegateesWithCustomPolicy.length();
                toolInfo.delegatees = new address[](delegateesLength);
                toolInfo.delegateesPolicyIpfsCids = new string[](delegateesLength);
                toolInfo.delegateesPolicyEnabled = new bool[](delegateesLength);
                
                for (uint256 j = 0; j < delegateesLength;) {
                    address delegatee = tool.delegateesWithCustomPolicy.at(j);
                    PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
                    toolInfo.delegatees[j] = delegatee;
                    toolInfo.delegateesPolicyIpfsCids[j] = l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash];
                    toolInfo.delegateesPolicyEnabled[j] = policy.enabled;
                    unchecked { ++j; }
                }
                
                toolsInfo[index] = toolInfo;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that have no policies set
    /// @param pkpTokenId The PKP token ID
    /// @return toolsWithoutPolicy Array of ToolInfoWithDelegatees structs for tools that have no policies
    function getToolsWithoutPolicy(uint256 pkpTokenId)
        external
        view
        returns (ToolInfoWithDelegatees[] memory toolsWithoutPolicy)
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
        toolsWithoutPolicy = new ToolInfoWithDelegatees[](count);
        uint256 index;
        for (uint256 i = 0; i < toolsLength;) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            if (tool.delegateesWithCustomPolicy.length() == 0) {
                ToolInfoWithDelegatees memory toolInfo;
                toolInfo.toolIpfsCid = l.hashedToolCidToOriginalCid[toolCidHash];
                toolInfo.toolEnabled = tool.enabled;
                toolInfo.delegatees = new address[](0); // No delegatees since there are no policies
                toolsWithoutPolicy[index] = toolInfo;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /// @notice Get all tools that are permitted for a specific delegatee
    /// @param pkpTokenId The PKP token ID
    /// @param delegatee The address of the delegatee
    /// @return permittedTools Array of ToolInfoWithDelegateePolicy structs for tools that are permitted for the delegatee
    function getPermittedToolsForDelegatee(uint256 pkpTokenId, address delegatee)
        external
        view
        returns (ToolInfoWithDelegateePolicy[] memory permittedTools)
    {
        if (delegatee == address(0)) revert LibPKPToolRegistryToolFacet.InvalidDelegatee();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

        // Get all permitted tools for this delegatee
        bytes32[] memory permittedToolHashes = new bytes32[](pkpData.toolCids.length());
        uint256 permittedCount;

        // Collect all permitted tool hashes in a single pass
        for (uint256 i = 0; i < pkpData.toolCids.length();) {
            bytes32 toolCidHash = pkpData.toolCids.at(i);
            if (delegateeData.permittedToolsForPkp[pkpTokenId].contains(toolCidHash)) {
                permittedToolHashes[permittedCount] = toolCidHash;
                unchecked { ++permittedCount; }
            }
            unchecked { ++i; }
        }

        // Initialize return array with exact size needed
        permittedTools = new ToolInfoWithDelegateePolicy[](permittedCount);

        // Fill array with tool info
        for (uint256 i = 0; i < permittedCount;) {
            bytes32 toolCidHash = permittedToolHashes[i];
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            
            (string memory policyIpfsCid, bool policyEnabled) = _getDelegateeToolPolicy(
                tool,
                delegatee,
                l
            );

            permittedTools[i] = ToolInfoWithDelegateePolicy({
                toolIpfsCid: l.hashedToolCidToOriginalCid[toolCidHash],
                toolEnabled: tool.enabled,
                delegatee: delegatee,
                policyIpfsCid: policyIpfsCid,
                policyEnabled: policyEnabled
            });
            
            unchecked { ++i; }
        }
    }

    /// @dev Helper function to get policy information for a delegatee's tool
    /// @param tool The tool info struct
    /// @param delegatee The delegatee address
    /// @param l The storage layout
    /// @return policyIpfsCid The IPFS CID of the policy, or empty string if none exists
    /// @return policyEnabled Whether the policy is enabled
    function _getDelegateeToolPolicy(
        PKPToolRegistryStorage.ToolInfo storage tool,
        address delegatee,
        PKPToolRegistryStorage.Layout storage l
    ) private view returns (string memory policyIpfsCid, bool policyEnabled) {
        if (!tool.delegateesWithCustomPolicy.contains(delegatee)) {
            return ("", false);
        }

        PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
        return (
            l.hashedPolicyCidToOriginalCid[policy.policyIpfsCidHash],
            policy.enabled
        );
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
        if (toolIpfsCids.length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool already exists
            if (pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolAlreadyRegistered(toolIpfsCid);
            }

            // Add to tools set and set enabled state
            l.hashedToolCidToOriginalCid[toolCidHash] = toolIpfsCid;
            pkpData.toolCids.add(toolCidHash);
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = enabled;

            unchecked { ++i; }
        }

        emit LibPKPToolRegistryToolFacet.ToolsRegistered(pkpTokenId, enabled, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCid);
            }

            // Clean up policies and permissions for each delegatees
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            address[] memory pkpDelegatees = pkpData.delegatees.values();
            for (uint256 j = 0; j < pkpDelegatees.length;) {
                address delegatee = pkpDelegatees[j];
                PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

                // Remove the policy if it exists
                if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                    PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
                    
                    // Get all parameter hashes before we start cleaning up
                    bytes32[] memory paramHashes = new bytes32[](policy.parameterNameHashes.length());
                    uint256 numParams = policy.parameterNameHashes.length();
                    for (uint256 k = 0; k < numParams;) {
                        paramHashes[k] = policy.parameterNameHashes.at(k);
                        unchecked { ++k; }
                    }
                    
                    // Clean up all parameters
                    for (uint256 k = 0; k < numParams;) {
                        bytes32 paramNameHash = paramHashes[k];
                        policy.parameterNameHashes.remove(paramNameHash);
                        delete l.hashedParameterNameToOriginalName[paramNameHash];
                        delete policy.parameters[paramNameHash];
                        unchecked { ++k; }
                    }
                    
                    // Finally delete the policy struct
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

        emit LibPKPToolRegistryToolFacet.ToolsRemoved(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCid);
            }

            // Enable the tool
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = true;

            unchecked { ++i; }
        }

        emit LibPKPToolRegistryToolFacet.ToolsEnabled(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string memory toolIpfsCid = toolIpfsCids[i];
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();
            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            
            // Check if tool exists
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCid);
            }

            // Disable the tool
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            tool.enabled = false;

            unchecked { ++i; }
        }

        emit LibPKPToolRegistryToolFacet.ToolsDisabled(pkpTokenId, toolIpfsCids);
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
        if (toolIpfsCids.length != delegatees.length) revert LibPKPToolRegistryToolFacet.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string calldata toolIpfsCid = toolIpfsCids[i];
            address delegatee = delegatees[i];

            if (delegatee == address(0)) revert LibPKPToolRegistryToolFacet.InvalidDelegatee();
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCid);
            }

            // Add tool to delegatee's permitted tools
            PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];
            delegateeData.permittedToolsForPkp[pkpTokenId].add(toolCidHash);

            unchecked { ++i; }
        }

        emit LibPKPToolRegistryToolFacet.ToolsPermitted(pkpTokenId, toolIpfsCids, delegatees);
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
        if (toolIpfsCids.length != delegatees.length) revert LibPKPToolRegistryToolFacet.ArrayLengthMismatch();

        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        for (uint256 i = 0; i < toolIpfsCids.length;) {
            string calldata toolIpfsCid = toolIpfsCids[i];
            address delegatee = delegatees[i];

            if (delegatee == address(0)) revert LibPKPToolRegistryToolFacet.InvalidDelegatee();
            if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryToolFacet.EmptyIPFSCID();

            bytes32 toolCidHash = keccak256(bytes(toolIpfsCid));
            if (!pkpData.toolCids.contains(toolCidHash)) {
                revert LibPKPToolRegistryToolFacet.ToolNotFound(toolIpfsCid);
            }

            // Clean up policies and permissions
            PKPToolRegistryStorage.ToolInfo storage tool = pkpData.toolMap[toolCidHash];
            PKPToolRegistryStorage.Delegatee storage delegateeData = l.delegatees[delegatee];

            // Remove the policy if it exists
            if (tool.delegateesWithCustomPolicy.remove(delegatee)) {
                PKPToolRegistryStorage.Policy storage policy = tool.delegateeCustomPolicies[delegatee];
                
                // Get all parameter hashes before we start cleaning up
                bytes32[] memory paramHashes = new bytes32[](policy.parameterNameHashes.length());
                uint256 numParams = policy.parameterNameHashes.length();
                for (uint256 k = 0; k < numParams;) {
                    paramHashes[k] = policy.parameterNameHashes.at(k);
                    unchecked { ++k; }
                }
                
                // Clean up all parameters
                for (uint256 k = 0; k < numParams;) {
                    bytes32 paramNameHash = paramHashes[k];
                    policy.parameterNameHashes.remove(paramNameHash);
                    delete l.hashedParameterNameToOriginalName[paramNameHash];
                    delete policy.parameters[paramNameHash];
                    unchecked { ++k; }
                }
                
                // Finally delete the policy struct
                delete tool.delegateeCustomPolicies[delegatee];
            }

            // Remove the tool from permitted tools
            delegateeData.permittedToolsForPkp[pkpTokenId].remove(toolCidHash);

            unchecked { ++i; }
        }

        emit LibPKPToolRegistryToolFacet.ToolsUnpermitted(pkpTokenId, toolIpfsCids, delegatees);
    }
} 