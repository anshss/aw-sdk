import {
  type Admin as FssAdmin,
  type FssTool,
} from '@lit-protocol/full-self-signing';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { handleGetTools } from './get-tools';

const promptSelectToolForPolicy = async (
  toolsWithPolicies: FssTool<any, any>[]
) => {
  const choices = toolsWithPolicies.map((tool) => ({
    title: `${tool.name} (${tool.ipfsCid})`,
    value: tool,
  }));

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to view policy:',
    choices,
  });

  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED,
      'Tool policy viewing cancelled.'
    );
  }

  return tool;
};

const getToolPolicy = async (fssAdmin: FssAdmin, tool: FssTool<any, any>) => {
  logger.loading('Getting tool policy...');
  const { policy, version } = await fssAdmin.getToolPolicy(tool.ipfsCid);

  logger.info('Tool Policy:');
  logger.log(`${tool.name} (${tool.ipfsCid})`);
  logger.log(`Version: ${version}`);
  logger.log(`Policy: ${policy}`);
};

export const handleGetToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await handleGetTools(fssAdmin);

    if (permittedTools === null) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    await getToolPolicy(
      fssAdmin,
      await promptSelectToolForPolicy(permittedTools.toolsWithPolicies)
    );
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS) {
        logger.error('No permitted tools with policies found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED) {
        logger.error('Tool policy viewing cancelled.');
        return;
      }
    }

    throw error;
  }
};
