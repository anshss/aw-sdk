// Import the FssTool and FssDelegatee types from the '@lit-protocol/full-self-signing' package.
import {
  FssTool,
  getToolByIpfsCid,
  type Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import the prompt utility for selecting a PKP.
import { promptSelectPkp } from '../../prompts/delegatee';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

/**
 * Retrieves and categorizes tools registered for a selected PKP (Programmable Key Pair).
 * This function logs the progress of the operation and handles cases where no PKPs or tools are found.
 *
 * @param fssDelegatee - An instance of the FssDelegatee class.
 * @returns An object containing:
 *   - pkpInfo: The selected PKP.
 *   - toolsWithPolicies: An array of tools with policies.
 *   - toolsWithoutPolicies: An array of tools without policies.
 *   If no PKPs are delegated, the function returns `null`.
 */
const getRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting registered tools...');

  // Retrieve the list of PKPs delegated to the user.
  const pkps = await fssDelegatee.getDelegatedPkps();

  // If no PKPs are delegated, log an error message and return `null`.
  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return null;
  }

  // Prompt the user to select a PKP.
  const selectedPkp = await promptSelectPkp(pkps);

  // Initialize arrays to store tools with and without policies.
  const toolsWithPolicies: FssTool<any, any>[] = [];
  const toolsWithoutPolicies: FssTool<any, any>[] = [];

  // Retrieve the list of registered tools for the selected PKP.
  const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
    selectedPkp.tokenId
  );

  // Process tools with policies.
  if (registeredTools.toolsWithPolicies.length > 0) {
    logger.log(`Tools with Policies:`);
    registeredTools.toolsWithPolicies.forEach((registeredTool) => {
      // Retrieve the tool details from the registry using its IPFS CID.
      const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);

      // If the tool is not found in the registry, log it as an unknown tool.
      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${registeredTool.ipfsCid}`);
      }
      // If the tool is found and matches the current Lit network, add it to the list.
      else if (
        registryTool &&
        registryTool.network === fssDelegatee.litNetwork
      ) {
        toolsWithPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${registeredTool.ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  // Process tools without policies.
  if (registeredTools.toolsWithoutPolicies.length > 0) {
    logger.log(`Tools without Policies:`);
    registeredTools.toolsWithoutPolicies.forEach((ipfsCid) => {
      // Retrieve the tool details from the registry using its IPFS CID.
      const registryTool = getToolByIpfsCid(ipfsCid);

      // If the tool is not found in the registry, log it as an unknown tool.
      if (registryTool === null) {
        logger.log(`  - Unknown tool: ${ipfsCid}`);
      }
      // If the tool is found and matches the current Lit network, add it to the list.
      else if (
        registryTool &&
        registryTool.network === fssDelegatee.litNetwork
      ) {
        toolsWithoutPolicies.push(registryTool.tool);
        logger.log(`  - ${registryTool.tool.name} (${ipfsCid})`);
        logger.log(`      - ${registryTool.tool.description}`);
      }
    });
  }

  // Return the selected PKP and categorized tools.
  return {
    pkpInfo: selectedPkp,
    toolsWithPolicies,
    toolsWithoutPolicies,
  };
};

/**
 * Handles the process of retrieving and displaying registered tools for a selected PKP.
 * This function retrieves the list of delegated PKPs, prompts the user to select a PKP,
 * retrieves the registered tools, and handles any errors that occur during the process.
 *
 * @param fssDelegatee - An instance of the FssDelegatee class.
 */
export const handleGetRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  try {
    // Retrieve the registered tools for the selected PKP.
    const result = await getRegisteredTools(fssDelegatee);

    // If no PKPs are delegated, exit.
    if (result === null) return;

    // Destructure the result to get tools with and without policies.
    const { toolsWithPolicies, toolsWithoutPolicies } = result;

    // If no tools are found for the selected PKP, log an informational message and exit.
    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      logger.info('No tools are registered for this PKP.');
      return;
    }
  } catch (error) {
    // Handle specific errors related to tool retrieval.
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        // Log an error message if the user cancels the PKP selection.
        logger.error('No PKP selected');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
