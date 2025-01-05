import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import {
  promptConfirmRemoval,
  promptSelectToolForRemoval,
} from '../../prompts/admin/remove-tool';

const getAndDisplayPermittedTools = async (fssAdmin: FssAdmin) => {
  logger.loading('Getting permitted tools');
  const permittedTools = await fssAdmin.getRegisteredTools();

  if (
    permittedTools.toolsWithPolicies.length === 0 &&
    permittedTools.toolsWithoutPolicies.length === 0
  ) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
      'No tools are currently permitted.'
    );
  }

  logger.info('Currently Permitted Tools:');

  if (permittedTools.toolsWithPolicies.length > 0) {
    logger.log('Tools with Policies:');
    permittedTools.toolsWithPolicies.forEach((tool) => {
      logger.log(`  - IPFS CID: ${tool.ipfsCid}`);
    });
  }

  if (permittedTools.toolsWithoutPolicies.length > 0) {
    logger.log('Tools without Policies:');
    permittedTools.toolsWithoutPolicies.forEach((ipfsCid) => {
      logger.log(`  - IPFS CID: ${ipfsCid}`);
    });
  }

  return permittedTools;
};

const removeTool = async (fssAdmin: FssAdmin, ipfsCid: string) => {
  await promptConfirmRemoval(ipfsCid);

  logger.loading('Removing tool...');
  await fssAdmin.removeTool(ipfsCid);
  logger.success('Tool removed successfully.');
};

export const handleRemoveTool = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await getAndDisplayPermittedTools(fssAdmin);
    await removeTool(
      fssAdmin,
      await promptSelectToolForRemoval(permittedTools)
    );
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS) {
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED) {
        logger.error('Tool removal cancelled.');
        return;
      }
    }

    throw error;
  }
};
