// Import the FssAdmin, FssTool, and PermittedTools types from the '@lit-protocol/agent-wallet' package.
import {
  type Admin as FssAdmin,
  type PermittedTools,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Retrieves and displays the list of permitted tools in the Full Self-Signing (FSS) system.
 * This function categorizes tools into those with policies and those without policies,
 * and filters them based on the current Lit network.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @returns A Promise that resolves to a `PermittedTools` object containing:
 *   - toolsWithPolicies: An array of tools with policies.
 *   - toolsWithoutPolicies: An array of tools without policies.
 *   If no tools are found, the function returns `null`.
 */
export const handleGetTools = async (
  fssAdmin: FssAdmin
): Promise<PermittedTools | null> => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting permitted tools');

  const registeredTools = await fssAdmin.getRegisteredToolsForPkp();


  // If no tools are found, log an informational message and return `null`.
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
