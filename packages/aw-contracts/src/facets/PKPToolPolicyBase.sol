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
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[toolIpfsCid];

        if (!toolInfo.enabled) {
            revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
        }
    }
} 