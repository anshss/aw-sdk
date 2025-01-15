// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IPKPNFTFacet.sol";
import "./libraries/PKPToolPolicyStorage.sol";
import "./libraries/PKPToolPolicyErrors.sol";

/**
 * @title PKPToolPolicyRegistry
 * @dev Registry for managing PKP-specific tool policies using Lit Actions.
 * Each PKP's owner can set policies for tools and manage delegatees who are
 * authorized to execute the tools.
 *
 * Each tool policy is a Lit Action that returns a boolean indicating whether
 * the execution is authorized. The policy can access on-chain parameters and
 * integrate with external services.
 *
 * Policy Format:
 * - Lit Action IPFS CID that returns { response: boolean }
 * - On-chain parameters accessible via bytes4(keccak256(parameterName))
 *
 * Policy Precedence:
 * - Delegatee-specific policies take precedence over blanket policies
 * - Blanket policies (set with delegatee = address(0)) apply to all delegatees
 *   unless they have a specific policy set
 *
 * IPFS CID Format:
 * - Must be a valid IPFS CID v0
 * - Represents either the tool code or policy code stored on IPFS
 * - Cannot be empty
 */
contract PKPToolPolicyRegistry {
    constructor(address _pkpNFT) {
        if (_pkpNFT == address(0)) revert PKPToolPolicyErrors.InvalidPKPTokenId();
        PKPToolPolicyStorage.Layout storage l = PKPToolPolicyStorage.layout();
        l.pkpNftContract = _pkpNFT;
    }
}
