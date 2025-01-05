import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import {
  promptConfirmPermit,
  promptSelectToolToPermit,
} from '../../prompts/admin/permit-tool';
import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { FssTool } from '@lit-protocol/fss-tool';

const getAndDisplayAlreadyPermittedTools = async (fssAdmin: FssAdmin) => {
  logger.loading('Getting already permitted tools');
  const alreadyPermittedTools = await fssAdmin.getRegisteredTools();

  if (
    alreadyPermittedTools.toolsWithPolicies.length === 0 &&
    alreadyPermittedTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return;
  }

  logger.info('Currently Permitted Tools:');

  if (alreadyPermittedTools.toolsWithPolicies.length > 0) {
    logger.log('Tools with Policies:');
    alreadyPermittedTools.toolsWithPolicies.forEach((tool) => {
      logger.log(`  - IPFS CID: ${tool.ipfsCid}`);
    });
  }

  if (alreadyPermittedTools.toolsWithoutPolicies.length > 0) {
    logger.log('Tools without Policies:');
    alreadyPermittedTools.toolsWithoutPolicies.forEach((ipfsCid) => {
      logger.log(`  - IPFS CID: ${ipfsCid}`);
    });
  }

  return alreadyPermittedTools;
};

const permitTool = async (fssAdmin: FssAdmin, tool: FssTool) => {
  await promptConfirmPermit(tool);

  logger.loading('Permitting tool...');
  await fssAdmin.permitTool({ ipfsCid: tool.ipfsCid });
  logger.success('Tool permitted successfully.');
};

export const handlePermitTool = async (fssAdmin: FssAdmin) => {
  try {
    const alreadyPermittedTools = await getAndDisplayAlreadyPermittedTools(
      fssAdmin
    );

    await permitTool(
      fssAdmin,
      await promptSelectToolToPermit(alreadyPermittedTools)
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
