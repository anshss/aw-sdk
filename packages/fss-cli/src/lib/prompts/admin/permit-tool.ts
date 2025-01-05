import prompts from 'prompts';
import { listTools } from '@lit-protocol/fss-tool-registry';
import type { RegisteredTool } from '@lit-protocol/fss-signer';
import type { FssTool } from '@lit-protocol/fss-tool';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectToolToPermit = async (alreadyPermittedTools?: {
  toolsWithPolicies: RegisteredTool[];
  toolsWithoutPolicies: string[];
}) => {
  const availableTools = listTools();

  // Create a set of already permitted IPFS CIDs for efficient lookup
  const permittedCids = new Set([
    ...(alreadyPermittedTools?.toolsWithPolicies.map((tool) => tool.ipfsCid) ||
      []),
    ...(alreadyPermittedTools?.toolsWithoutPolicies || []),
  ]);

  // Filter out already permitted tools
  const unpermittedTools = availableTools.filter(
    (tool) => !permittedCids.has(tool.ipfsCid)
  );

  if (unpermittedTools.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS,
      'No unpermitted tools found.'
    );
  }

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to permit:',
    choices: unpermittedTools.map((tool) => ({
      title: tool.name,
      description: tool.description,
      value: tool,
    })),
  });

  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool permitting cancelled.'
    );
  }

  return tool;
};

export const promptConfirmPermit = async (tool: FssTool) => {
  logger.log('');
  logger.log(`Name: ${tool.name}`);
  logger.log(`Description: ${tool.description}`);
  logger.log(`IPFS CID: ${tool.ipfsCid}`);
  logger.log('');

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Are you sure you want to permit this tool?',
    initial: true,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool permitting cancelled.'
    );
  }

  return confirmed;
};
