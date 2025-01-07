import {
  type Admin as FssAdmin,
  type FssTool,
  getToolByIpfsCid,
  type PermittedTools,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

export const handleGetTools = async (
  fssAdmin: FssAdmin
): Promise<PermittedTools | null> => {
  logger.loading('Getting permitted tools');
  const permittedTools = await fssAdmin.getRegisteredTools();

  if (
    permittedTools.toolsWithPolicies.length === 0 &&
    permittedTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return null;
  }

  const toolsWithPolicies: FssTool<any, any>[] = [];
  const toolsWithoutPolicies: FssTool<any, any>[] = [];

  logger.info('Currently Permitted Tools:');

  if (permittedTools.toolsWithPolicies.length > 0) {
    logger.log('Tools with Policies:');
    permittedTools.toolsWithPolicies.forEach((registeredTool) => {
      const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);

      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${registeredTool.ipfsCid}`);
      } else if (registryTool && registryTool.network === fssAdmin.litNetwork) {
        toolsWithPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${registeredTool.ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  if (permittedTools.toolsWithoutPolicies.length > 0) {
    logger.log('Tools without Policies:');
    permittedTools.toolsWithoutPolicies.forEach((ipfsCid) => {
      const registryTool = getToolByIpfsCid(ipfsCid);

      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${ipfsCid}`);
      } else if (registryTool && registryTool.network === fssAdmin.litNetwork) {
        toolsWithoutPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
    logger.info(`No tools found for network: ${fssAdmin.litNetwork}`);
    return null;
  }

  return {
    toolsWithPolicies,
    toolsWithoutPolicies,
  };
};
