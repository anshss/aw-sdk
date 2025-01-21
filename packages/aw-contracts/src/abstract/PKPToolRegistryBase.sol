// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IPKPNFTFacet.sol";
import "../libraries/PKPToolRegistryStorage.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibPKPToolRegistryBase {
    error NotPKPOwner();
    error EmptyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
}

using EnumerableSet for EnumerableSet.Bytes32Set;

/// @title PKP Tool Policy Base Contract
/// @notice Base contract for PKP tool policy management, providing core functionality and access control
/// @dev Abstract contract that implements common functionality for PKP tool registry facets
abstract contract PKPToolRegistryBase {
    /// @notice Retrieves the storage layout for the contract
    /// @dev Virtual function to allow derived contracts to override storage layout if needed
    /// @return PKPToolRegistryStorage.Layout storage reference to the contract's storage layout
    function _layout() internal pure virtual returns (PKPToolRegistryStorage.Layout storage) {
        return PKPToolRegistryStorage.layout();
    }

    /// @notice Restricts function access to the owner of a specific PKP token
    /// @dev Reverts with NotPKPOwner if caller is not the owner of the specified PKP
    /// @param pkpTokenId The ID of the PKP token to check ownership for
    modifier onlyPKPOwner(uint256 pkpTokenId) {
        PKPToolRegistryStorage.Layout storage layout = _layout();
        if (msg.sender != IPKPNFTFacet(layout.pkpNftContract).ownerOf(pkpTokenId)) {
            revert LibPKPToolRegistryBase.NotPKPOwner();
        }
        _;
    }

    /// @notice Verifies that a tool exists (is registered) for a specific PKP
    /// @dev Reverts with EmptyIPFSCID if CID is empty or ToolNotFound if tool doesn't exist
    /// @param pkpTokenId The ID of the PKP token to check the tool for
    /// @param toolIpfsCid The IPFS CID of the tool to verify
    modifier verifyToolExists(
        uint256 pkpTokenId,
        string memory toolIpfsCid
    ) {
        if (bytes(toolIpfsCid).length == 0) revert LibPKPToolRegistryBase.EmptyIPFSCID();

        bytes32 hashedCid = keccak256(bytes(toolIpfsCid));
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        PKPToolRegistryStorage.PKPData storage pkpData = l.pkpStore[pkpTokenId];

        if (!pkpData.toolCids.contains(hashedCid)) {
            revert LibPKPToolRegistryBase.ToolNotFound(toolIpfsCid);
        }
        _;
    }

    /// @notice Get the PKP NFT contract address
    /// @dev Returns the address of the PKP NFT contract used for ownership verification
    /// @return address The address of the PKP NFT contract
    function getPKPNFTContract() external view returns (address) {
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        return l.pkpNftContract;
    }
} 