// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyErrors {
    error NotPKPOwner();
    error EmptyIPFSCID();
    error EmptyPolicyIPFSCID();
    error ToolNotFound(string toolIpfsCid);
    error InvalidPolicyParameter();
    error NoPolicySet();
    error ArrayLengthMismatch();
    error InvalidPKPTokenId();
    error EmptyDelegatees();

    error ZeroAddressCannotBeDelegatee();
    error DelegateeAlreadyExists(uint256 pkpTokenId, address delegatee);
    error DelegateeNotFound(uint256 pkpTokenId, address delegatee);
} 