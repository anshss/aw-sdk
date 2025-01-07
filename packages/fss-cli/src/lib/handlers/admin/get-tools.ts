// Import the FssAdmin, FssTool, and PermittedTools types from the '@lit-protocol/full-self-signing' package.
import {
  type Admin as FssAdmin,
  type FssTool,
  getToolByIpfsCid,
  type PermittedTools,
} from '@lit-protocol/full-self-signing';

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

  // Retrieve the list of permitted tools from the FSS system.
  const permittedTools = await fssAdmin.getRegisteredTools();

  // If no tools are found, log an informational message and return `null`.
  if (
    permittedTools.toolsWithPolicies.length === 0 &&
    permittedTools.toolsWithoutPolicies.length === 0
  ) {
    logger.info('No tools are currently permitted.');
    return null;
  }

  // Initialize arrays to store tools with and without policies.
  const toolsWithPolicies: FssTool<any, any>[] = [];
  const toolsWithoutPolicies: FssTool<any, any>[] = [];

  // Log the header for the list of permitted tools.
  logger.info('Currently Permitted Tools:');

  // Process tools with policies.
  if (permittedTools.toolsWithPolicies.length > 0) {
    logger.log('Tools with Policies:');
    permittedTools.toolsWithPolicies.forEach((registeredTool) => {
      // Retrieve the tool details from the registry using its IPFS CID.
      const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);

      // If the tool is not found in the registry, log it as an unknown tool.
      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${registeredTool.ipfsCid}`);
      }
      // If the tool is found and matches the current Lit network, add it to the list.
      else if (registryTool && registryTool.network === fssAdmin.litNetwork) {
        toolsWithPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${registeredTool.ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  // Process tools without policies.
  if (permittedTools.toolsWithoutPolicies.length > 0) {
    logger.log('Tools without Policies:');
    permittedTools.toolsWithoutPolicies.forEach((ipfsCid) => {
      // Retrieve the tool details from the registry using its IPFS CID.
      const registryTool = getToolByIpfsCid(ipfsCid);

      // If the tool is not found in the registry, log it as an unknown tool.
      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${ipfsCid}`);
      }
      // If the tool is found and matches the current Lit network, add it to the list.
      else if (registryTool && registryTool.network === fssAdmin.litNetwork) {
        toolsWithoutPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  // If no tools are found for the current Lit network, log an informational message and return `null`.
  if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
    logger.info(`No tools found for network: ${fssAdmin.litNetwork}`);
    return null;
  }

  // Return the categorized tools.
  return {
    toolsWithPolicies,
    toolsWithoutPolicies,
  };
};
