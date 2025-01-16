// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PKPToolPolicyDelegateeEvents.sol";
import "./PKPToolPolicyToolEvents.sol";
import "./PKPToolPolicyPolicyEvents.sol";
import "./PKPToolPolicyParameterEvents.sol";

/// @title PKP Tool Policy Events
/// @notice A library that combines all PKP Tool Policy related events
/// @dev This library imports and exposes events from specialized event libraries
library PKPToolPolicyEvents {
    // Re-export all events from specialized libraries
    using PKPToolPolicyDelegateeEvents for *;
    using PKPToolPolicyToolEvents for *;
    using PKPToolPolicyPolicyEvents for *;
    using PKPToolPolicyParameterEvents for *;
} 