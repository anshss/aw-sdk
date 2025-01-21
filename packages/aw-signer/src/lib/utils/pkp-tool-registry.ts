import { LIT_RPC } from '@lit-protocol/constants';
import { ethers } from 'ethers';
import { type LitContracts } from '@lit-protocol/contracts-sdk';
import bs58 from 'bs58';
// import { getToolByIpfsCid } from '@lit-protocol/aw-tool-registry';
// import type { AwTool } from '@lit-protocol/aw-tool';

// import { ToolRegistryConfig, UnknownRegisteredToolWithPolicy } from '../types';
import { ToolRegistryConfig } from '../types';

export const DEFAULT_REGISTRY_CONFIG: Record<string, ToolRegistryConfig> = {
  'datil-dev': {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0x0f6Bc1a669701944d8603C35f0BD839893aa481e',
  },
  'datil-test': {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0x99d07dF918475D9069accf75a410c6DE68e67741',
  },
  datil: {
    rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
    contractAddress: '0xddd73dcb3c5b05AbBE25146DF18450040578CA40',
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

  'function getRegisteredTools(uint256 pkpTokenId) external view returns (string[] memory toolIpfsCids)',
  'function getRegisteredToolsAndPolicies(uint256 pkpTokenId) external view returns (string[] memory toolIpfsCids, string[][] memory delegateePolicyCids, address[] memory delegatees)',
  'function getToolsWithPolicy(uint256 pkpTokenId) external view returns (string[] memory toolsWithPolicy, address[][] memory delegateesWithPolicy)',
  'function getToolsWithoutPolicy(uint256 pkpTokenId) external view returns (string[] memory toolsWithoutPolicy)',

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
  'event ToolsRegistered(uint256 indexed pkpTokenId, string[] toolIpfsCids, bool indexed enabled)',
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

/**
 * Get all registered tools and categorize them based on whether they have policies
 * @returns Object containing arrays of tools with and without policies, and unknown tools
 */
export const getRegisteredTools = async (
  toolPolicyRegistryContract: ethers.Contract,
  litContracts: LitContracts,
  pkpTokenId: string
  // ): Promise<{
  //   toolsWithPolicies: Array<{
  //     tool: AwTool<any, any>;
  //     network: string;
  //   }>;
  //   toolsWithoutPolicies: Array<{
  //     tool: AwTool<any, any>;
  //     network: string;
  //   }>;
  //   toolsUnknownWithPolicies: UnknownRegisteredToolWithPolicy[];
  //   toolsUnknownWithoutPolicies: string[];
  // }> => {
): Promise<void> => {
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
  const [toolIpfsCids, delegateePolicyCids, delegatees] =
    await toolPolicyRegistryContract.getRegisteredToolsAndPolicies(pkpTokenId);

  console.log('base58PermittedTools', base58PermittedTools);
  console.log('toolIpfsCids', toolIpfsCids);
  console.log('delegateePolicyCids', delegateePolicyCids);
  console.log('delegatees', delegatees);

  toolIpfsCids.forEach((ipfsCid: string, i: number) => {
    console.log('ipfsCid', ipfsCid);
    console.log('delegatee', delegatees[i]);
    console.log('delegateePolicyCids[i]', delegateePolicyCids[i]);
  });

  // const toolsWithPolicies: Array<{
  //   tool: AwTool<any, any>;
  //   network: string;
  // }> = [];
  // const toolsWithoutPolicies: Array<{
  //   tool: AwTool<any, any>;
  //   network: string;
  // }> = [];
  // const toolsUnknownWithPolicies: UnknownRegisteredToolWithPolicy[] = [];
  // const toolsUnknownWithoutPolicies: string[] = [];

  // // Process tools with policies
  // toolIpfsCids.forEach((cid: string, i: number) => {
  //   const registryTool = getToolByIpfsCid(cid);
  //   const hasPolicies = delegateePolicyCids[i].some(
  //     (policy: string) => policy !== ''
  //   );

  //   if (registryTool === null) {
  //     if (hasPolicies) {
  //       toolsUnknownWithPolicies.push({
  //         ipfsCid: cid,
  //         policy: delegateePolicyCids[i][0],
  //         version: '1.0.0',
  //       });
  //     } else {
  //       toolsUnknownWithoutPolicies.push(cid);
  //     }
  //   } else {
  //     if (hasPolicies) {
  //       toolsWithPolicies.push({
  //         tool: registryTool.tool,
  //         network: registryTool.network,
  //       });
  //     } else {
  //       toolsWithoutPolicies.push({
  //         tool: registryTool.tool,
  //         network: registryTool.network,
  //       });
  //     }
  //   }
  // });

  // // Process permitted tools that are not registered
  // base58PermittedTools
  //   .filter((tool) => !toolIpfsCids.includes(tool))
  //   .forEach((ipfsCid) => {
  //     const registryTool = getToolByIpfsCid(ipfsCid);

  //     if (registryTool === null) {
  //       toolsUnknownWithoutPolicies.push(ipfsCid);
  //     } else {
  //       toolsWithoutPolicies.push({
  //         tool: registryTool.tool,
  //         network: registryTool.network,
  //       });
  //     }
  //   });

  // return {
  //   toolsWithPolicies,
  //   toolsWithoutPolicies,
  //   toolsUnknownWithPolicies,
  //   toolsUnknownWithoutPolicies,
  // };
};

/**
 * Get the policy for a specific tool and delegatee
 * @param ipfsCid IPFS CID of the tool
 * @param delegatee Address of the delegatee
 * @returns The policy IPFS CID and enabled status for the tool
 */
export const getToolPolicy = async (
  toolPolicyRegistryContract: ethers.Contract,
  pkpTokenId: string,
  ipfsCid: string,
  delegatee: string
): Promise<{ policyIpfsCid: string; enabled: boolean }> => {
  const [policyIpfsCid, enabled] =
    await toolPolicyRegistryContract.getToolPolicyForDelegatee(
      pkpTokenId,
      ipfsCid,
      delegatee
    );

  return { policyIpfsCid, enabled };
};
