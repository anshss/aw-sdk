import prompts from 'prompts';
import { type RegisteredTool } from '@lit-protocol/fss-signer';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectTool = async (
  toolsWithPolicies: RegisteredTool[],
  toolsWithoutPolicies: string[]
) => {
  const allTools = [
    ...toolsWithPolicies.map((tool) => ({
      title: `${tool.ipfsCid} (Version: ${tool.version})`,
      value: tool.ipfsCid,
      hasPolicy: true,
    })),
    ...toolsWithoutPolicies.map((ipfsCid) => ({
      title: `${ipfsCid} (No Policy)`,
      value: ipfsCid,
      hasPolicy: false,
    })),
  ];

  if (allTools.length === 0) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
      'No tools available to select'
    );
  }

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool:',
    choices: allTools,
  });

  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_SELECT_TOOL_CANCELLED,
      'No tool selected'
    );
  }

  return {
    ipfsCid: tool,
    hasPolicy: allTools.find((t) => t.value === tool)?.hasPolicy ?? false,
  };
};
