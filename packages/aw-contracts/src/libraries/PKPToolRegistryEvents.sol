// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolRegistryDelegateeEvents.sol";
import "./PKPToolRegistryToolEvents.sol";
import "./PKPToolRegistryPolicyEvents.sol";
import "./PKPToolRegistryParameterEvents.sol";

/// @title PKP Tool Registry Events
/// @notice A library that combines all PKP Tool Registry related events
/// @dev This library imports and exposes events from specialized event libraries
library PKPToolRegistryEvents {
    // Re-export all events from specialized libraries
    using PKPToolRegistryDelegateeEvents for *;
    using PKPToolRegistryToolEvents for *;
    using PKPToolRegistryPolicyEvents for *;
    using PKPToolRegistryParameterEvents for *;
} 