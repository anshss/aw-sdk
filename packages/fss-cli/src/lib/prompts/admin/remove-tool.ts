import prompts from 'prompts';
import type { PermittedTools, FssTool } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectToolForRemoval = async (
  alreadyPermittedTools: PermittedTools
): Promise<FssTool<any, any>> => {
  const choices = [
    ...alreadyPermittedTools.toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
    })),
    ...alreadyPermittedTools.toolsWithoutPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
    })),
  ];

  if (choices.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
      'No permitted tools found.'
    );
  }

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to remove:',
    choices,
  });

  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }

  return tool;
};

export const promptConfirmRemoval = async (tool: FssTool<any, any>) => {
  logger.log('');
  logger.log(`${tool.name} (${tool.ipfsCid})`);
  logger.log('');

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Are you sure you want to remove this tool?',
    initial: false,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }
};
