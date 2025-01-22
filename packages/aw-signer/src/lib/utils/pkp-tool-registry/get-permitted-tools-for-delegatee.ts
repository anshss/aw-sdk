import { getToolByIpfsCid } from '@lit-protocol/aw-tool-registry';
import { ethers } from 'ethers';
import { AwTool } from '@lit-protocol/aw-tool';

type RegistryToolResult = ReturnType<typeof getToolByIpfsCid>;

type ToolMetadata = AwTool & {
  network: string;
  toolEnabled?: boolean;
};

type PermittedToolWithPolicy = ToolMetadata & {
  delegatee: string;
  policyIpfsCid: string;
  policyEnabled: boolean;
};

type PermittedToolWithoutPolicy = ToolMetadata & {
  delegatee: string;
};

type UnknownPermittedToolWithPolicy = {
  toolIpfsCid: string;
  toolEnabled: boolean;
  delegatee: string;
  policyIpfsCid: string;
  policyEnabled: boolean;
};

type UnknownPermittedToolWithoutPolicy = {
  toolIpfsCid: string;
  toolEnabled: boolean;
  delegatee: string;
};

type PermittedToolsResult = {
  toolsWithPolicies: { [ipfsCid: string]: PermittedToolWithPolicy };
  toolsWithoutPolicies: { [ipfsCid: string]: PermittedToolWithoutPolicy };
  toolsUnknownWithPolicies: {
    [ipfsCid: string]: UnknownPermittedToolWithPolicy;
  };
  toolsUnknownWithoutPolicies: UnknownPermittedToolWithoutPolicy[];
};

type ToolInfo = {
  toolIpfsCid: string;
  toolEnabled: boolean;
  delegatee: string;
  policyIpfsCid: string;
  policyEnabled: boolean;
};

/**
 * Process a tool that isn't found in the registry
 */
const processUnknownTool = (
  toolInfo: ToolInfo,
  hasPolicy: boolean,
  result: PermittedToolsResult
) => {
  if (hasPolicy) {
    result.toolsUnknownWithPolicies[toolInfo.toolIpfsCid] = {
      toolIpfsCid: toolInfo.toolIpfsCid,
      toolEnabled: toolInfo.toolEnabled,
      delegatee: toolInfo.delegatee,
      policyIpfsCid: toolInfo.policyIpfsCid,
      policyEnabled: toolInfo.policyEnabled,
    };
  } else {
    result.toolsUnknownWithoutPolicies.push({
      toolIpfsCid: toolInfo.toolIpfsCid,
      toolEnabled: toolInfo.toolEnabled,
      delegatee: toolInfo.delegatee,
    });
  }
};

/**
 * Process a tool that is found in the registry
 */
const processKnownTool = (
  toolInfo: ToolInfo,
  hasPolicy: boolean,
  registryTool: NonNullable<RegistryToolResult>,
  result: PermittedToolsResult
) => {
  const baseToolInfo = {
    name: registryTool.tool.name,
    description: registryTool.tool.description,
    ipfsCid: registryTool.tool.ipfsCid,
    parameters: registryTool.tool.parameters,
    policy: registryTool.tool.policy,
    network: registryTool.network,
    toolEnabled: toolInfo.toolEnabled,
    delegatee: toolInfo.delegatee,
    defaultPolicyIpfsCid: registryTool.tool.defaultPolicyIpfsCid,
  };

  if (hasPolicy) {
    result.toolsWithPolicies[toolInfo.toolIpfsCid] = {
      ...baseToolInfo,
      policyIpfsCid: toolInfo.policyIpfsCid,
      policyEnabled: toolInfo.policyEnabled,
    };
  } else {
    result.toolsWithoutPolicies[toolInfo.toolIpfsCid] = baseToolInfo;
  }
};

/**
 * Process a single tool from the registry
 */
const processRegistryTool = async (
  toolInfo: ToolInfo,
  result: PermittedToolsResult
) => {
  const hasPolicy = toolInfo.policyIpfsCid !== '';
  const registryTool: RegistryToolResult = await getToolByIpfsCid(
    toolInfo.toolIpfsCid
  );

  if (registryTool === null) {
    processUnknownTool(toolInfo, hasPolicy, result);
  } else {
    processKnownTool(toolInfo, hasPolicy, registryTool, result);
  }
};

/**
 * Get all tools that are permitted for a specific delegatee
 * @returns Object containing:
 * - toolsWithPolicies: Object mapping tool IPFS CIDs to tools that have policies and match the current network
 * - toolsWithoutPolicies: Object mapping tool IPFS CIDs to tools that don't have policies and match the current network
 * - toolsUnknownWithPolicies: Object mapping tool IPFS CIDs to tools with policies that aren't in the registry
 * - toolsUnknownWithoutPolicies: Array of tools without policies that aren't in the registry
 */
export const getPermittedToolsForDelegatee = async (
  toolPolicyRegistryContract: ethers.Contract,
  pkpTokenId: string,
  delegatee: string
): Promise<PermittedToolsResult> => {
  // Get tools permitted for this delegatee from registry contract
  const toolsInfo =
    await toolPolicyRegistryContract.getPermittedToolsForDelegatee(
      pkpTokenId,
      delegatee
    );

  const result: PermittedToolsResult = {
    toolsWithPolicies: {},
    toolsWithoutPolicies: {},
    toolsUnknownWithPolicies: {},
    toolsUnknownWithoutPolicies: [],
  };

  // Process each tool from the registry
  await Promise.all(
    toolsInfo.map((toolInfo: ToolInfo) => processRegistryTool(toolInfo, result))
  );

  return result;
};

export type {
  PermittedToolsResult,
  PermittedToolWithPolicy,
  PermittedToolWithoutPolicy,
};
