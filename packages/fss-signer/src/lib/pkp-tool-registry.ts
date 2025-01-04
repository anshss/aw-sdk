import { ethers } from 'ethers';

import { ToolPolicyRegistryConfig } from './types';

export const POLICY_ABI = [
  'function setActionPolicy(address pkp, bytes memory policy) external',
  'function getActionPolicy(address pkp, bytes32 ipfsCid) external view returns (bytes memory policy, string memory version)',
] as const;

export const getPkpToolPolicyRegistryContract = (
  toolPolicyRegistryConfig: ToolPolicyRegistryConfig
) => {
  return new ethers.Contract(
    toolPolicyRegistryConfig.contractAddress,
    POLICY_ABI,
    new ethers.providers.JsonRpcProvider(toolPolicyRegistryConfig.rpcUrl)
  );
};
