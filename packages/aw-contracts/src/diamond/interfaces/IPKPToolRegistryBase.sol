// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title PKP Tool Registry Base Interface
/// @notice Interface for base functions shared across all facets
interface IPKPToolRegistryBase {
    /// @notice Get the PKP NFT contract address
    /// @dev Returns the address of the PKP NFT contract used for ownership verification
    /// @return address The address of the PKP NFT contract
    function getPKPNFTContract() external view returns (address);
} 