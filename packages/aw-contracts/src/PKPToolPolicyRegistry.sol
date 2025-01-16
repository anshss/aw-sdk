// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IPKPNFTFacet.sol";
import "./libraries/PKPToolPolicyStorage.sol";
import "./libraries/PKPToolPolicyErrors.sol";

/// @title PKP Tool Policy Registry
/// @notice Core contract for managing programmable PKP tool policies using Lit Actions
/// @dev Implements diamond storage pattern for upgradeable policy management
/// @custom:security-contact security@litprotocol.com
contract PKPToolPolicyRegistry {
    /// @notice Initializes the registry with a PKP NFT contract reference
    /// @dev Sets up the diamond storage layout with the PKP NFT contract address
    /// @param _pkpNFT The address of the PKP NFT contract
    /// @custom:throws InvalidPKPTokenId if _pkpNFT is the zero address
    constructor(address _pkpNFT) {
        if (_pkpNFT == address(0)) revert PKPToolPolicyErrors.InvalidPKPTokenId();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        l.pkpNftContract = _pkpNFT;
    }
}

/// @notice Policy Format
/// @dev Each policy is a Lit Action that must conform to the following format:
/// - Must be stored on IPFS with a valid CIDv0
/// - Must return { response: boolean } indicating authorization
/// - Can access on-chain parameters via bytes4(keccak256(parameterName))
/// - Can integrate with external services for complex authorization logic

/// @notice Policy Precedence Rules
/// @dev The system follows these rules when evaluating policies:
/// 1. Delegatee-specific policies take precedence over blanket policies
/// 2. Blanket policies (delegatee = address(0)) apply as fallback
/// 3. If no policy exists, access is denied by default

/// @notice IPFS Requirements
/// @dev All IPFS CIDs in the system must:
/// 1. Be valid IPFS CID v0 format
/// 2. Not be empty strings
/// 3. Point to either tool code or policy code
/// 4. Be accessible on the IPFS network
