// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyParameterEvents {
    event BlanketPolicyParametersSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames,
        bytes[] parameterValues
    );

    event BlanketPolicyParametersRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames
    );

    event PolicyParametersSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string[] parameterNames,
        bytes[] parameterValues
    );

    event PolicyParametersRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        address indexed delegatee,
        string[] parameterNames
    );
} 