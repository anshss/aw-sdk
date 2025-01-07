import {
  type Admin as FssAdmin,
  type FssTool,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import {
  promptConfirmRemoval,
  promptSelectToolForRemoval,
} from '../../prompts/admin/remove-tool';
import { handleGetTools } from './get-tools';

const removeTool = async (fssAdmin: FssAdmin, tool: FssTool<any, any>) => {
  await promptConfirmRemoval(tool);

  logger.loading('Removing tool...');
  await fssAdmin.removeTool(tool.ipfsCid);
  logger.success('Tool removed successfully.');
};

export const handleRemoveTool = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await handleGetTools(fssAdmin);

    if (permittedTools === null) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
        'No tools are currently permitted.'
      );
    }

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
