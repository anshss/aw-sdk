import { Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import {
  promptConfirmPermit,
  promptSelectToolToPermit,
} from '../../prompts/admin/permit-tool';
import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { FssTool } from '@lit-protocol/fss-tool';
import { handleGetTools } from './get-tools';

const permitTool = async (fssAdmin: FssAdmin, tool: FssTool) => {
  await promptConfirmPermit(tool);

  logger.loading('Permitting tool...');
  await fssAdmin.permitTool({ ipfsCid: tool.ipfsCid });
  logger.success('Tool permitted successfully.');
};

export const handlePermitTool = async (fssAdmin: FssAdmin) => {
  try {
    const alreadyPermittedTools = await handleGetTools(fssAdmin);

    await permitTool(
      fssAdmin,
      await promptSelectToolToPermit(fssAdmin.litNetwork, alreadyPermittedTools)
    );
  } catch (error) {
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS
      ) {
        logger.error('No unpermitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED) {
        logger.error('Tool permitting cancelled.');
        return;
      }
    }

    throw error;
  }
};
