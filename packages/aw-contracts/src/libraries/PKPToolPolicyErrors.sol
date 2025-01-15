// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyErrors {
    error InvalidPKPTokenId();
    error ToolNotFound(string ipfsCid);
    error EmptyIPFSCID();
    error EmptyPolicyIPFSCID();
    error EmptyDelegatees();
    error NotPKPOwner();
    error InvalidPolicyParameter();
    error InvalidDelegatee();
    error PolicyParameterNotFound(string parameterName);
    error NoPolicySet();
} 