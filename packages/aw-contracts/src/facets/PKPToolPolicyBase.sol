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
} 