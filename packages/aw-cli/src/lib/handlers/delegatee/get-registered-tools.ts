import { type Delegatee as AwDelegatee } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import the prompt utility for selecting a PKP.
import { promptSelectPkp } from '../../prompts/delegatee';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Retrieves and categorizes tools registered for a selected PKP (Programmable Key Pair).
 * This function logs the progress of the operation and handles cases where no PKPs or tools are found.
 *
 * @param awDelegatee - An instance of the AwDelegatee class.
 * @returns An object containing:
 *   - pkpInfo: The selected PKP.
 *   - toolsWithPolicies: An array of tools with policies.
 *   - toolsWithoutPolicies: An array of tools without policies.
 *   If no PKPs are delegated, the function returns `null`.
 */
const getRegisteredTools = async (awDelegatee: AwDelegatee) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting registered tools...');

  // Retrieve the list of PKPs delegated to the user.
  const pkps = await awDelegatee.getDelegatedPkps();

  // If no PKPs are delegated, log an error message and return `null`.
  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return null;
  }

  // Prompt the user to select a PKP.
  const selectedPkp = await promptSelectPkp(pkps);

  const registeredTools = await awDelegatee.getPermittedToolsForPkp(
    selectedPkp.tokenId
  );

  // Process tools with policies.
  if (Object.keys(registeredTools.toolsWithPolicies).length > 0) {
    logger.log(`Tools with Policies:`);
    Object.values(registeredTools.toolsWithPolicies).forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - Tool Enabled: ${tool.toolEnabled ? '✅' : '❌'}`);
      logger.log(`      - Description: ${tool.description}`);
      logger.log(`      - Policy: ${tool.policyIpfsCid}`);
      logger.log(`      - Policy Enabled: ${tool.policyEnabled ? '✅' : '❌'}`);
    });
  }

  // Process tools without policies.
  if (Object.keys(registeredTools.toolsWithoutPolicies).length > 0) {
    logger.log(`Tools without Policies:`);
    Object.values(registeredTools.toolsWithoutPolicies).forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - Tool Enabled: ${tool.toolEnabled ? '✅' : '❌'}`);
      logger.log(`      - Description: ${tool.description}`);
    });
  }

  if (Object.keys(registeredTools.toolsUnknownWithPolicies).length > 0) {
    logger.log(`Unknown Tools with Policies:`);
    Object.values(registeredTools.toolsUnknownWithPolicies).forEach((tool) => {
      logger.log(`  - ${tool.toolIpfsCid}`);
      logger.log(`      - Tool Enabled: ${tool.toolEnabled ? '✅' : '❌'}`);
      logger.log(`      - Policy: ${tool.policyIpfsCid}`);
      logger.log(`      - Policy Enabled: ${tool.policyEnabled ? '✅' : '❌'}`);
    });
  }

  if (registeredTools.toolsUnknownWithoutPolicies.length > 0) {
    logger.log(`Unknown Tools without Policies:`);
    registeredTools.toolsUnknownWithoutPolicies.forEach((tool) => {
      logger.log(`  - ${tool.toolIpfsCid}`);
      logger.log(`      - Tool Enabled: ${tool.toolEnabled ? '✅' : '❌'}`);
    });
  }

  // Return the selected PKP and categorized tools.
  return {
    pkpInfo: selectedPkp,
    toolsWithPolicies: registeredTools.toolsWithPolicies,
    toolsWithoutPolicies: registeredTools.toolsWithoutPolicies,
  };
};

/**
 * Handles the process of retrieving and displaying registered tools for a selected PKP.
 * This function retrieves the list of delegated PKPs, prompts the user to select a PKP,
 * retrieves the registered tools, and handles any errors that occur during the process.
 *
 * @param awDelegatee - An instance of the AwDelegatee class.
 */
export const handleGetRegisteredTools = async (awDelegatee: AwDelegatee) => {
  try {
    // Retrieve the registered tools for the selected PKP.
    const result = await getRegisteredTools(awDelegatee);

    // If no PKPs are delegated, exit.
    if (result === null) return;

    // Destructure the result to get tools with and without policies.
    const { toolsWithPolicies, toolsWithoutPolicies } = result;

    // If no tools are found for the selected PKP, log an informational message and exit.
    if (
      Object.keys(toolsWithPolicies).length === 0 &&
      Object.keys(toolsWithoutPolicies).length === 0
    ) {
      logger.info('No tools are registered for this PKP.');
      return;
    }
  } catch (error) {
    // Handle specific errors related to tool retrieval.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        // Log an error message if the user cancels the PKP selection.
        logger.error('No PKP selected');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
