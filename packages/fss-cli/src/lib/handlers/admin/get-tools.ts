import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

export const handleGetTools = async (fssAdmin: FssAdmin) => {
  logger.loading('Getting permitted tools');
  const permittedTools = await fssAdmin.getRegisteredTools();

  if (
    permittedTools.toolsWithPolicies.length === 0 &&
    permittedTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return;
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
