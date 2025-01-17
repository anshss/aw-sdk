// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IDiamondCut.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC173.sol";
import "../../libraries/PKPToolRegistryStorage.sol";
import "../../libraries/PKPToolRegistryErrors.sol";

contract PKPToolRegistryInit {
    /// @notice Initialize the PKPToolRegistry Diamond
    /// @param _pkpNftContract The address of the PKP NFT contract
    function init(address _pkpNftContract) external {
        if (_pkpNftContract == address(0)) revert PKPToolRegistryErrors.InvalidPKPTokenId();
        
        // Initialize PKPToolRegistry storage
        PKPToolRegistryStorage.Layout storage l = PKPToolRegistryStorage.layout();
        l.pkpNftContract = _pkpNftContract;

        // Initialize ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }
} 