// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IPKPNFTFacet.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

abstract contract PKPToolPolicyBase {
    function _layout() internal pure virtual returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    modifier onlyPKPOwner(uint256 pkpTokenId) {
        PKPToolPolicyStorage.Layout storage layout = _layout();
        if (msg.sender != IPKPNFTFacet(layout.pkpNftContract).ownerOf(pkpTokenId)) {
            revert PKPToolPolicyErrors.NotPKPOwner();
        }
        _;
    }

    /// @notice Modifier to verify a tool is registered
    /// @param pkpTokenId The PKP token ID
    /// @param toolIpfsCid The IPFS CID of the tool to verify
    modifier verifyToolRegistered(
        uint256 pkpTokenId,
        string memory toolIpfsCid
    ) {
        if (bytes(toolIpfsCid).length == 0) revert PKPToolPolicyErrors.EmptyIPFSCID();

        bytes32 hashedCid = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        PKPToolPolicyStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];
        PKPToolPolicyStorage.ToolInfo storage toolInfo = pkpData.toolMap[hashedCid];

        if (!toolInfo.enabled) {
            revert PKPToolPolicyErrors.ToolNotFound(toolIpfsCid);
        }
        _;
    }

    /// @notice Internal function to hash a tool's IPFS CID
    /// @param toolIpfsCid The IPFS CID to hash
    /// @return The keccak256 hash of the IPFS CID
    function _hashToolCid(string memory toolIpfsCid) internal pure returns (bytes32) {
        return keccak256(bytes(toolIpfsCid));
    }

    /// @notice Internal function to get the original tool CID from its hash
    /// @param hashedCid The hashed CID to look up
    /// @return The original IPFS CID string
    function _getOriginalToolCid(bytes32 hashedCid) internal view returns (string memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.hashedToolCidToOriginalCid[hashedCid];
    }

    /// @notice Internal function to store a tool CID and its hash
    /// @param toolIpfsCid The IPFS CID to store
    /// @return The hash of the stored CID
    function _storeToolCid(string memory toolIpfsCid) internal returns (bytes32) {
        bytes32 hashedCid = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        l.hashedToolCidToOriginalCid[hashedCid] = toolIpfsCid;
        return hashedCid;
    }
} 