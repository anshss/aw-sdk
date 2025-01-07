import prompts from 'prompts';
import {
  listToolsByNetwork,
  type FssTool,
  type LitNetwork,
  type PermittedTools,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectToolToPermit = async (
  litNetwork: LitNetwork,
  alreadyPermittedTools: PermittedTools | null
) => {
  const availableTools = listToolsByNetwork(litNetwork);

  // Create a set of already permitted IPFS CIDs for efficient lookup
  const permittedCids = new Set([
    ...(alreadyPermittedTools?.toolsWithPolicies.map(
      (tool: FssTool<any, any>) => tool.ipfsCid
    ) || []),
    ...(alreadyPermittedTools?.toolsWithoutPolicies.map(
      (tool: FssTool<any, any>) => tool.ipfsCid
    ) || []),
  ]);

  // Filter out already permitted tools
  const unpermittedTools = availableTools.filter(
    (tool: FssTool<any, any>) => !permittedCids.has(tool.ipfsCid)
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
    choices: unpermittedTools.map((tool: FssTool<any, any>) => ({
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

  return tool as FssTool<any, any>;
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
