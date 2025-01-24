// Import the AwAdmin, AwTool, and PermittedTools types from the '@lit-protocol/agent-wallet' package.
import type {
  PkpInfo,
  Admin as AwAdmin,
  RegisteredToolsResult,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Retrieves and displays the list of permitted tools in the Full Self-Signing (AW) system.
 * This function categorizes tools into those with policies and those without policies,
 * and filters them based on the current Lit network.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @returns A Promise that resolves to a `PermittedTools` object containing:
 *   - toolsWithPolicies: An array of tools with policies.
 *   - toolsWithoutPolicies: An array of tools without policies.
 *   If no tools are found, the function returns `null`.
 */
export const handleGetTools = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<RegisteredToolsResult | null> => {
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
    for (const toolIpfsCid in registeredTools.toolsWithPolicies) {
      const tool = registeredTools.toolsWithPolicies[toolIpfsCid];
      logger.log(`  - ${tool.name} (${toolIpfsCid})`);
      logger.log(`      - ${tool.description}`);
    }
  }

  if (Object.keys(registeredTools.toolsWithoutPolicies).length > 0) {
    logger.log('Tools without Policies:');
    for (const toolIpfsCid in registeredTools.toolsWithoutPolicies) {
      const tool = registeredTools.toolsWithoutPolicies[toolIpfsCid];
      logger.log(`  - ${tool.name} (${toolIpfsCid})`);
      logger.log(`      - ${tool.description}`);
    }
  }

  if (Object.keys(registeredTools.toolsUnknownWithPolicies).length > 0) {
    logger.log('Unknown Tools with Policies:');
    for (const toolIpfsCid in registeredTools.toolsUnknownWithPolicies) {
      logger.log(`  - Unknown tool: ${toolIpfsCid}`);
    }
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

  return registeredTools;
};
