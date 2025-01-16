// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PKPToolPolicyParameterEvents {
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