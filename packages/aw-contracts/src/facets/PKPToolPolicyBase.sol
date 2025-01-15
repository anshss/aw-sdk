// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IPKPNFTFacet.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyBase {
    function _layout() internal pure returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    modifier onlyPKPOwner(uint256 pkpTokenId) {
        PKPToolPolicyStorage.Layout storage layout = _layout();
        if (msg.sender != IPKPNFTFacet(layout.pkpNftContract).ownerOf(pkpTokenId)) {
            revert PKPToolPolicyErrors.NotPKPOwner();
        }
        _;
    }

    /// @notice Internal function to verify a tool is registered
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool to verify
    function _verifyToolRegistered(
        uint256 pkpTokenId,
        string memory toolIpfsCid
    ) internal view {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

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
    }
} 