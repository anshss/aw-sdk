// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/interfaces/IPKPNFTFacet.sol";

contract MockPKPNFT is IPKPNFTFacet {
    mapping(uint256 => address) private _owners;

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function setOwner(uint256 tokenId, address owner) external {
        _owners[tokenId] = owner;
    }
} 