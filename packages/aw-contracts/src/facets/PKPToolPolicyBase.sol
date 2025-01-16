// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IPKPNFTFacet.sol";
import "../libraries/PKPToolPolicyStorage.sol";
import "../libraries/PKPToolPolicyErrors.sol";

/// @title PKP Tool Policy Base Contract
/// @notice Base contract for PKP tool policy management, providing core functionality and access control
/// @dev Abstract contract that implements common functionality for PKP tool policy facets
abstract contract PKPToolPolicyBase {
    /// @notice Retrieves the storage layout for the contract
    /// @dev Virtual function to allow derived contracts to override storage layout if needed
    /// @return PKPToolPolicyStorage.Layout storage reference to the contract's storage layout
    function _layout() internal pure virtual returns (PKPToolPolicyStorage.Layout storage) {
        return PKPToolPolicyStorage.layout();
    }

    /// @notice Restricts function access to the owner of a specific PKP token
    /// @dev Reverts with NotPKPOwner if caller is not the owner of the specified PKP
    /// @param pkpTokenId The ID of the PKP token to check ownership for
    modifier onlyPKPOwner(uint256 pkpTokenId) {
        PKPToolPolicyStorage.Layout storage layout = _layout();
        if (msg.sender != IPKPNFTFacet(layout.pkpNftContract).ownerOf(pkpTokenId)) {
            revert PKPToolPolicyErrors.NotPKPOwner();
        }
        _;
    }

    /// @notice Verifies that a tool is registered and enabled for a specific PKP
    /// @dev Reverts with EmptyIPFSCID if CID is empty or ToolNotFound if tool is not enabled
    /// @param pkpTokenId The ID of the PKP token to check the tool for
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

    /// @notice Computes the keccak256 hash of a tool's IPFS CID
    /// @dev Used for efficient storage and lookup of tool data
    /// @param toolIpfsCid The IPFS CID to hash
    /// @return bytes32 The keccak256 hash of the IPFS CID
    function _hashToolCid(string memory toolIpfsCid) internal pure returns (bytes32) {
        return keccak256(bytes(toolIpfsCid));
    }

    /// @notice Retrieves the original IPFS CID for a given hash
    /// @dev Used to convert from storage-optimized hash back to human-readable CID
    /// @param hashedCid The keccak256 hash of the IPFS CID to look up
    /// @return string The original IPFS CID string, or empty string if not found
    function _getOriginalToolCid(bytes32 hashedCid) internal view returns (string memory) {
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        return l.hashedToolCidToOriginalCid[hashedCid];
    }

    /// @notice Stores a tool's IPFS CID and its hash in storage
    /// @dev Maps the hash to the original CID for future lookups
    /// @param toolIpfsCid The IPFS CID to store
    /// @return bytes32 The keccak256 hash of the stored CID
    function _storeToolCid(string memory toolIpfsCid) internal returns (bytes32) {
        bytes32 hashedCid = _hashToolCid(toolIpfsCid);
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        l.hashedToolCidToOriginalCid[hashedCid] = toolIpfsCid;
        return hashedCid;
    }
} 