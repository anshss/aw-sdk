import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { handleGetTools } from './get-tools';

const promptSelectToolForPolicy = async (
  toolsWithPolicies: Array<{ ipfsCid: string }>
) => {
  if (toolsWithPolicies.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS,
      'No tools with policies found.'
    );
  }

  const choices = toolsWithPolicies.map((tool) => ({
    title: tool.ipfsCid,
    value: tool.ipfsCid,
  }));

  const { ipfsCid } = await prompts({
    type: 'select',
    name: 'ipfsCid',
    message: 'Select a tool to view policy:',
    choices,
  });

  if (!ipfsCid) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED,
      'Tool policy viewing cancelled.'
    );
  }

  return ipfsCid;
};

const getToolPolicy = async (fssAdmin: FssAdmin, ipfsCid: string) => {
  logger.loading('Getting tool policy...');
  const { policy, version } = await fssAdmin.getToolPolicy(ipfsCid);

  logger.info('Tool Policy:');
  logger.log(`IPFS CID: ${ipfsCid}`);
  logger.log(`Version: ${version}`);
  logger.log(`Policy: ${policy}`);
};

export const handleGetToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await handleGetTools(fssAdmin);

    if (
      permittedTools === undefined ||
      (permittedTools.toolsWithPolicies.length === 0 &&
        permittedTools.toolsWithoutPolicies.length === 0)
    ) {
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
