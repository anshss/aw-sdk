import { LIT_RPC } from '@lit-protocol/constants';
import { ethers } from 'ethers';
import { type LitContracts } from '@lit-protocol/contracts-sdk';
import bs58 from 'bs58';
import { getToolByIpfsCid } from '@lit-protocol/fss-tool-registry';
import type { FssTool } from '@lit-protocol/fss-tool';

import {
  UnknownRegisteredToolWithPolicy,
  ToolPolicyRegistryConfig,
} from '../types';

export const DEFAULT_REGISTRY_CONFIG: Record<string, ToolPolicyRegistryConfig> =
  {
    'datil-dev': {
      rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
      contractAddress: '0xdE8807799579eef5b9A84A0b4164D28E804da571',
    },
    'datil-test': {
      rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
      contractAddress: '0x0b099F7e2520aCC52A361D1cB83fa43660C9a038',
    },
    datil: {
      rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
      contractAddress: '0xDeb70dCBC7432fEFEdaE900AFF11Dcc5169CfcBB',
    },
  } as const;

const PKP_TOOL_POLICY_REGISTRY_ABI = [
  // View Functions
  'function getDelegatees(uint256 pkpTokenId) external view returns (address[] memory)',
  'function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool)',
  'function getToolPolicy(uint256 pkpTokenId, string calldata ipfsCid) external view returns (bytes memory policy, string memory version)',
  'function getRegisteredTools(uint256 pkpTokenId) external view returns (string[] memory ipfsCids, bytes[] memory policies, string[] memory versions)',
  'function getDelegatedPkps(address delegatee) external view returns (uint256[] memory)',

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

/**
 * Get all registered tools and categorize them based on whether they have policies
 * @returns Object containing arrays of tools with and without policies, and unknown tools
 */
export const getRegisteredTools = async (
  toolPolicyRegistryContract: ethers.Contract,
  litContracts: LitContracts,
  pkpTokenId: string
): Promise<{
  toolsWithPolicies: Array<{
    tool: FssTool<any, any>;
    network: string;
  }>;
  toolsWithoutPolicies: Array<{
    tool: FssTool<any, any>;
    network: string;
  }>;
  toolsUnknownWithPolicies: UnknownRegisteredToolWithPolicy[];
  toolsUnknownWithoutPolicies: string[];
}> => {
  // Get all permitted tools
  const permittedTools =
    await litContracts.pkpPermissionsContractUtils.read.getPermittedActions(
      pkpTokenId
    );

  // Convert hex CIDs to base58
  const base58PermittedTools = permittedTools.map((hexCid) => {
    // Remove '0x' prefix and convert to Buffer
    const bytes = Buffer.from(hexCid.slice(2), 'hex');
    return bs58.encode(bytes);
  });

  // Get tools with policies
  const [ipfsCids, policyData, versions] =
    await toolPolicyRegistryContract.getRegisteredTools(pkpTokenId);

  const toolsWithPolicies: Array<{
    tool: FssTool<any, any>;
    network: string;
  }> = [];
  const toolsWithoutPolicies: Array<{
    tool: FssTool<any, any>;
    network: string;
  }> = [];
  const toolsUnknownWithPolicies: UnknownRegisteredToolWithPolicy[] = [];
  const toolsUnknownWithoutPolicies: string[] = [];

  // Process tools with policies
  ipfsCids.forEach((cid: string, i: number) => {
    const registryTool = getToolByIpfsCid(cid);

    if (registryTool === null) {
      toolsUnknownWithPolicies.push({
        ipfsCid: cid,
        policy: policyData[i],
        version: versions[i],
      });
    } else {
      toolsWithPolicies.push({
        tool: registryTool.tool,
        network: registryTool.network,
      });
    }
  });

  // Process tools without policies
  base58PermittedTools
    .filter((tool) => !ipfsCids.includes(tool))
    .forEach((ipfsCid) => {
      const registryTool = getToolByIpfsCid(ipfsCid);

      if (registryTool === null) {
        toolsUnknownWithoutPolicies.push(ipfsCid);
      } else {
        toolsWithoutPolicies.push({
          tool: registryTool.tool,
          network: registryTool.network,
        });
      }
    });

  return {
    toolsWithPolicies,
    toolsWithoutPolicies,
    toolsUnknownWithPolicies,
    toolsUnknownWithoutPolicies,
  };
};

/**
 * Get the policy for a specific tool
 * @param ipfsCid IPFS CID of the tool
 * @returns The policy and version for the tool
 */
// TODO: Decode the policy bytes string to a string
export const getToolPolicy = async (
  toolPolicyRegistryContract: ethers.Contract,
  pkpTokenId: string,
  ipfsCid: string
): Promise<{ policy: string; version: string }> => {
  const [policy, version] = await toolPolicyRegistryContract.getToolPolicy(
    pkpTokenId,
    ipfsCid
  );

  return { policy, version };
};
