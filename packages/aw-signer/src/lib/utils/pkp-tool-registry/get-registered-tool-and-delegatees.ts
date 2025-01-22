import { type LitContracts } from '@lit-protocol/contracts-sdk';
import { getToolByIpfsCid } from '@lit-protocol/aw-tool-registry';
import { ethers } from 'ethers';
import bs58 from 'bs58';

type RegistryToolResult = ReturnType<typeof getToolByIpfsCid>;

type ToolMetadata = NonNullable<RegistryToolResult>['tool'] & {
  network: NonNullable<RegistryToolResult>['network'];
  toolEnabled?: boolean;
};

type RegisteredToolWithPolicies = ToolMetadata & {
  delegateePolicies: {
    [delegatee: string]: {
      policyIpfsCid: string;
      policyEnabled: boolean;
    };
  };
};

type RegisteredToolsResult = {
  toolsWithPolicies: {
    [ipfsCid: string]: RegisteredToolWithPolicies;
  };
  toolsWithoutPolicies: {
    [ipfsCid: string]: ToolMetadata;
  };
  toolsUnknownWithPolicies: {
    [ipfsCid: string]: {
      toolEnabled: boolean;
      delegateePolicies: {
        [delegatee: string]: {
          policyIpfsCid: string;
          policyEnabled: boolean;
        };
      };
    };
  };
  toolsUnknownWithoutPolicies: string[];
};

type ToolInfo = {
  toolIpfsCid: string;
  toolEnabled: boolean;
  delegatees: string[];
  delegateesPolicyIpfsCids: string[];
  delegateesPolicyEnabled: boolean[];
};

/**
 * Process delegatee policies for a tool
 */
const processDelegateePolicies = (toolInfo: ToolInfo) => {
  return toolInfo.delegatees.reduce(
    (
      acc: {
        [delegatee: string]: {
          policyIpfsCid: string;
          policyEnabled: boolean;
        };
      },
      delegatee: string,
      i: number
    ) => {
      if (toolInfo.delegateesPolicyIpfsCids[i] !== '') {
        acc[delegatee] = {
          policyIpfsCid: toolInfo.delegateesPolicyIpfsCids[i],
          policyEnabled: toolInfo.delegateesPolicyEnabled[i],
        };
      }
      return acc;
    },
    {}
  );
};

/**
 * Process a tool that isn't found in the registry
 */
const processUnknownTool = (
  toolInfo: ToolInfo,
  hasPolicies: boolean,
  result: RegisteredToolsResult
) => {
  if (hasPolicies) {
    const delegateePolicies = processDelegateePolicies(toolInfo);
    result.toolsUnknownWithPolicies[toolInfo.toolIpfsCid] = {
      toolEnabled: toolInfo.toolEnabled,
      delegateePolicies,
    };
  } else {
    result.toolsUnknownWithoutPolicies.push(toolInfo.toolIpfsCid);
  }
};

/**
 * Process a tool that is found in the registry
 */
const processKnownTool = (
  toolInfo: ToolInfo,
  hasPolicies: boolean,
  registryTool: NonNullable<RegistryToolResult>,
  result: RegisteredToolsResult
) => {
  if (hasPolicies) {
    const delegateePolicies = processDelegateePolicies(toolInfo);
    result.toolsWithPolicies[toolInfo.toolIpfsCid] = {
      ...registryTool.tool,
      network: registryTool.network,
      toolEnabled: toolInfo.toolEnabled,
      delegateePolicies,
    };
  } else {
    result.toolsWithoutPolicies[toolInfo.toolIpfsCid] = {
      ...registryTool.tool,
      network: registryTool.network,
      toolEnabled: toolInfo.toolEnabled,
    };
  }
};

/**
 * Process a single tool from the registry
 */
const processRegistryTool = async (
  toolInfo: ToolInfo,
  result: RegisteredToolsResult
) => {
  const hasPolicies = toolInfo.delegatees.length > 0;
  const registryTool: RegistryToolResult = await getToolByIpfsCid(
    toolInfo.toolIpfsCid
  );

  if (registryTool === null) {
    processUnknownTool(toolInfo, hasPolicies, result);
  } else {
    processKnownTool(toolInfo, hasPolicies, registryTool, result);
  }
};

/**
 * Process tools that are permitted but not in the registry response
 */
const processPermittedTools = async (
  permittedTools: string[],
  toolsInfo: ToolInfo[],
  result: RegisteredToolsResult
) => {
  await Promise.all(
    permittedTools
      .filter((tool) => !toolsInfo.some((info) => info.toolIpfsCid === tool))
      .map(async (ipfsCid) => {
        const registryTool: RegistryToolResult = await getToolByIpfsCid(
          ipfsCid
        );

        if (registryTool === null) {
          result.toolsUnknownWithoutPolicies.push(ipfsCid);
        } else {
          result.toolsWithoutPolicies[ipfsCid] = {
            ...registryTool.tool,
            network: registryTool.network,
          };
        }
      })
  );
};

/**
 * Get all registered tools and categorize them based on whether they have policies
 * @returns Object containing:
 * - toolsWithPolicies: Object mapping tool IPFS CIDs to their metadata and delegatee policies
 * - toolsWithoutPolicies: Object mapping tool IPFS CIDs to their metadata without policies
 * - toolsUnknownWithPolicies: Object mapping unknown tool IPFS CIDs to their delegatee policies
 * - toolsUnknownWithoutPolicies: Array of tool CIDs without policies that aren't in the registry
 */
export const getRegisteredToolsAndDelegatees = async (
  toolPolicyRegistryContract: ethers.Contract,
  litContracts: LitContracts,
  pkpTokenId: string
): Promise<RegisteredToolsResult> => {
  // Get all permitted tools from PKP Permissions contract
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

  // Get tools and their policies from registry contract
  const toolsInfo =
    await toolPolicyRegistryContract.getRegisteredToolsAndDelegatees(
      pkpTokenId
    );

  const result: RegisteredToolsResult = {
    toolsWithPolicies: {},
    toolsWithoutPolicies: {},
    toolsUnknownWithPolicies: {},
    toolsUnknownWithoutPolicies: [],
  };

  // Process each tool from the registry
  await Promise.all(
    toolsInfo.map((toolInfo: ToolInfo) => processRegistryTool(toolInfo, result))
  );

  // Process permitted tools that aren't in the registry
  await processPermittedTools(base58PermittedTools, toolsInfo, result);

  return result;
};

export type { RegisteredToolsResult, RegisteredToolWithPolicies };
