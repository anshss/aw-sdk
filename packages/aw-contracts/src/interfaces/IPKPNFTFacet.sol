// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPKPNFTFacet {
    function ownerOf(uint256 tokenId) external view returns (address);
} 