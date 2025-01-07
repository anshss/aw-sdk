import prompts from 'prompts';
import { type FssTool } from '@lit-protocol/full-self-signing';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectTool = async (
  toolsWithPolicies: FssTool<any, any>[],
  toolsWithoutPolicies: FssTool<any, any>[]
) => {
  const allTools = [
    ...toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
      hasPolicy: true,
    })),
    ...toolsWithoutPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
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

  return tool as FssTool<any, any>;
};
