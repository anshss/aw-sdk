import { LIT_RPC } from '@lit-protocol/constants';
import { ethers } from 'ethers';

import { ToolRegistryConfig } from '../../types';

export const DEFAULT_REGISTRY_CONFIG: Record<string, ToolRegistryConfig> = {
  'datil-dev': {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0xe3367d943554099A7Df32e8d8D3AF7c4fAe4255c',
  },
  'datil-test': {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0xC376C11E0195b8bFfbD95a51d5F0D59D8B295510',
  },
  datil: {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0x72E7c2501b0f9B337D4df3D03e3a79D49c54780F',
  },
} as const;

const PKP_TOOL_REGISTRY_ABI = [
  // Tool Facet Functions
  'function registerTools(uint256 pkpTokenId, string[] calldata toolIpfsCids, bool enabled) external',
  'function removeTools(uint256 pkpTokenId, string[] calldata toolIpfsCids) external',

  'function enableTools(uint256 pkpTokenId, string[] calldata toolIpfsCids) external',
  'function disableTools(uint256 pkpTokenId, string[] calldata toolIpfsCids) external',

  'function permitToolsForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external',
  'function unpermitToolsForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external',

  'function getRegisteredTools(uint256 pkpTokenId, string[] calldata toolIpfsCids) external view returns (tuple(string toolIpfsCid, bool toolEnabled)[] memory toolsInfo)',
  'function getAllRegisteredTools(uint256 pkpTokenId) external view returns (tuple(string toolIpfsCid, bool toolEnabled)[] memory toolsInfo)',
  'function getRegisteredToolAndDelegatees(uint256 pkpTokenId, string calldata toolIpfsCid) external view returns (tuple(string toolIpfsCid, bool toolEnabled, address[] delegatees, string[] delegateesPolicyIpfsCids, bool[] delegateesPolicyEnabled) memory toolInfo)',
  'function getRegisteredToolsAndDelegatees(uint256 pkpTokenId) external view returns (tuple(string toolIpfsCid, bool toolEnabled, address[] delegatees, string[] delegateesPolicyIpfsCids, bool[] delegateesPolicyEnabled)[] memory toolsInfo)',
  'function getToolsWithPolicy(uint256 pkpTokenId) external view returns (tuple(string toolIpfsCid, bool toolEnabled, address[] delegatees, string[] delegateesPolicyIpfsCids, bool[] delegateesPolicyEnabled)[] memory toolsInfo)',
  'function getToolsWithoutPolicy(uint256 pkpTokenId) external view returns (tuple(string toolIpfsCid, bool toolEnabled, address[] delegatees)[] memory toolsWithoutPolicy)',

  'function isToolRegistered(uint256 pkpTokenId, string calldata toolIpfsCid) external view returns (bool isRegistered, bool isEnabled)',
  'function isToolPermittedForDelegatee(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee) external view returns (bool isPermitted, bool isEnabled)',

  // Delegatee Facet Functions
  'function addDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external',
  'function removeDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external',
  'function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory)',
  'function getDelegatedPkps(address delegatee) external view returns (uint256[] memory)',
  'function isPkpDelegatee(uint256 pkpTokenId, address delegatee) external view returns (bool)',

  // Policy Facet Functions
  'function getToolPolicyForDelegatee(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee) external view returns (string memory policyIpfsCid, bool enabled)',
  'function setToolPoliciesForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees, string[] calldata policyIpfsCids, bool enablePolicies) external',
  'function removeToolPoliciesForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external',
  'function enableToolPoliciesForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external',
  'function disableToolPoliciesForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external',

  // Policy Parameter Facet Functions
  'function getToolPolicyParameter(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee, string calldata parameterName) external view returns (bytes memory parameterValue)',
  'function getToolPolicyParameters(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee) external view returns (string[] memory parameterNames, bytes[] memory parameterValues)',
  'function setToolPolicyParametersForDelegatee(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee, string[] calldata parameterNames, bytes[] calldata parameterValues) external',
  'function removeToolPolicyParametersForDelegatee(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee, string[] calldata parameterNames) external',

  // Events
  'event ToolsRegistered(uint256 indexed pkpTokenId, bool enabled, string[] toolIpfsCids)',
  'event ToolsRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids)',
  'event ToolsEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids)',
  'event ToolsDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids)',
  'event ToolsPermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees)',
  'event AddedDelegatees(uint256 indexed pkpTokenId, address[] delegatees)',
  'event RemovedDelegatees(uint256 indexed pkpTokenId, address[] delegatees)',
  'event ToolPoliciesSet(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees, string[] policyIpfsCids)',
  'event ToolPoliciesRemoved(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees)',
  'event PoliciesEnabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees)',
  'event PoliciesDisabled(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees)',
  'event PolicyParametersSet(uint256 indexed pkpTokenId, string toolIpfsCids, address delegatee, string[] parameterNames, bytes[] parameterValues)',
  'event PolicyParametersRemoved(uint256 indexed pkpTokenId, string toolIpfsCids, address delegatee, string[] parameterNames)',
  'event ToolsUnpermitted(uint256 indexed pkpTokenId, string[] toolIpfsCids, address[] delegatees)',
];

export const getPkpToolRegistryContract = (
  { rpcUrl, contractAddress }: ToolRegistryConfig,
  signer: ethers.Signer
) => {
  const contract = new ethers.Contract(
    contractAddress,
    PKP_TOOL_REGISTRY_ABI,
    new ethers.providers.JsonRpcProvider(rpcUrl)
  );

  // Connect the signer to allow write operations
  return contract.connect(signer);
};
