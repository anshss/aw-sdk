import { ethers } from 'ethers';

import { ToolPolicyRegistryConfig } from '../types';

const PKP_TOOL_POLICY_REGISTRY_ABI = [
  // View Functions
  'function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory)',
  'function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool)',
  'function getToolPolicy(uint256 pkpTokenId, string calldata ipfsCid) external view returns (bytes memory policy, string memory version)',
  'function getRegisteredTools(uint256 pkpTokenId) external view returns (string[] memory ipfsCids, bytes[] memory policies, string[] memory versions)',

  // Write Functions
  'function addDelegatee(uint256 pkpTokenId, address delegatee) external',
  'function removeDelegatee(uint256 pkpTokenId, address delegatee) external',
  'function batchAddDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external',
  'function batchRemoveDelegatees(uint256 pkpTokenId, address[] calldata delegatees) external',
  'function setToolPolicy(uint256 pkpTokenId, string calldata ipfsCid, bytes calldata policy, string calldata version) external',
  'function removeToolPolicy(uint256 pkpTokenId, string calldata ipfsCid) external',

  // Events
  'event DelegateeAdded(uint256 indexed pkpTokenId, address indexed delegatee)',
  'event DelegateeRemoved(uint256 indexed pkpTokenId, address indexed delegatee)',
  'event ToolPolicySet(uint256 indexed pkpTokenId, string ipfsCid, bytes policy, string version)',
  'event ToolPolicyRemoved(uint256 indexed pkpTokenId, string ipfsCid)',
];

export const getPkpToolPolicyRegistryContract = (
  { rpcUrl, contractAddress }: ToolPolicyRegistryConfig,
  signer: ethers.Signer
) => {
  const contract = new ethers.Contract(
    contractAddress,
    PKP_TOOL_POLICY_REGISTRY_ABI,
    new ethers.providers.JsonRpcProvider(rpcUrl)
  );

  // Connect the signer to allow write operations
  return contract.connect(signer);
};
