import {
  type Admin as FssAdmin,
  type PermittedTools,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

export const handleGetTools = async (
  fssAdmin: FssAdmin
): Promise<PermittedTools | null> => {
  logger.loading('Getting permitted tools');
  const registeredTools = await fssAdmin.getRegisteredToolsForPkp();

  if (
    registeredTools.toolsWithPolicies.length === 0 &&
    registeredTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return null;
  }

  logger.info('Currently Permitted Tools:');

  if (registeredTools.toolsWithPolicies.length > 0) {
    logger.log('Tools with Policies:');
    registeredTools.toolsWithPolicies.forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (registeredTools.toolsWithoutPolicies.length > 0) {
    logger.log('Tools without Policies:');
    registeredTools.toolsWithoutPolicies.forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (registeredTools.toolsUnknownWithPolicies.length > 0) {
    logger.log('Unknown Tools with Policies:');
    registeredTools.toolsUnknownWithPolicies.forEach((tool) => {
      logger.log(`  - Unknown tool: ${tool.ipfsCid}`);
    });
  }

  if (registeredTools.toolsUnknownWithoutPolicies.length > 0) {
    logger.log('Unknown Tools without Policies:');
    registeredTools.toolsUnknownWithoutPolicies.forEach((ipfsCid) => {
      logger.log(`  - Unknown tool: ${ipfsCid}`);
    });
  }

  if (
    registeredTools.toolsWithPolicies.length === 0 &&
    registeredTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info(`No tools found for network: ${fssAdmin.litNetwork}`);
    return null;
  }

  return registeredTools;
};
