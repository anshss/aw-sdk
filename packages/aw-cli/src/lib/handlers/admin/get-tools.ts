// Import the AwAdmin, AwTool, and PermittedTools types from the '@lit-protocol/agent-wallet' package.
import type {
  Admin as AwAdmin,
  PkpInfo,
  AwTool,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

export type PermittedTools = {
  toolsWithPolicies: AwTool[];
  toolsWithoutPolicies: AwTool[];
};

/**
 * Retrieves and displays the list of permitted tools for a PKP.
 * This function logs the progress of the operation and handles cases where no tools are found.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to get tools for.
 * @returns A promise that resolves to the permitted tools or `null` if no tools are found.
 */
export const handleGetTools = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<PermittedTools | null> => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting permitted tools');

  const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(
    pkp.info.tokenId
  );

  // If no tools are found, log an informational message and return `null`.
  if (
    Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
    Object.keys(registeredTools.toolsWithoutPolicies).length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return null;
  }

  logger.info('Currently Permitted Tools:');

  if (Object.keys(registeredTools.toolsWithPolicies).length > 0) {
    logger.log('Tools with Policies:');
    Object.entries(registeredTools.toolsWithPolicies).forEach(([ipfsCid, tool]) => {
      logger.log(`  - ${tool.name} (${ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (Object.keys(registeredTools.toolsWithoutPolicies).length > 0) {
    logger.log('Tools without Policies:');
    Object.entries(registeredTools.toolsWithoutPolicies).forEach(([ipfsCid, tool]) => {
      logger.log(`  - ${tool.name} (${ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (Object.keys(registeredTools.toolsUnknownWithPolicies).length > 0) {
    logger.log('Unknown Tools with Policies:');
    Object.entries(registeredTools.toolsUnknownWithPolicies).forEach(([ipfsCid, tool]) => {
      logger.log(`  - Unknown tool: ${ipfsCid}`);
    });
  }

  if (registeredTools.toolsUnknownWithoutPolicies.length > 0) {
    logger.log('Unknown Tools without Policies:');
    registeredTools.toolsUnknownWithoutPolicies.forEach((ipfsCid) => {
      logger.log(`  - Unknown tool: ${ipfsCid}`);
    });
  }

  if (
    Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
    Object.keys(registeredTools.toolsWithoutPolicies).length === 0
  ) {
    logger.info(`No tools found for network: ${awAdmin.litNetwork}`);
    return null;
  }

  // Return the tools in the expected format
  return {
    toolsWithPolicies: Object.values(registeredTools.toolsWithPolicies),
    toolsWithoutPolicies: Object.values(registeredTools.toolsWithoutPolicies),
  };
};
