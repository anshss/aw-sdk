import { type Delegatee as AwDelegatee } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import prompt utilities for user interaction.
import { promptSelectPkp, promptSelectTool } from '../../prompts/delegatee';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Handles the process of retrieving and displaying the policy for a selected tool registered under a specific PKP.
 * This function retrieves the list of delegated PKPs, prompts the user to select a PKP and a tool,
 * retrieves the tool's policy, decodes it, and logs the result. It also handles errors that occur during the process.
 *
 * @param awDelegatee - An instance of the AwDelegatee class.
 */
export const handleGetToolPolicy = async (awDelegatee: AwDelegatee) => {
  try {
    // Retrieve the list of PKPs delegated to the user.
    const pkps = await awDelegatee.getDelegatedPkps();

    // If no PKPs are delegated, log a message and return.
    if (pkps.length === 0) {
      logger.info('No PKPs are currently delegated to you.');
      return;
    }

    // Prompt the user to select a PKP.
    const selectedPkp = await promptSelectPkp(pkps);

    // Retrieve the list of registered tools for the selected PKP.
    const registeredTools = await awDelegatee.getPermittedToolsForPkp(
      selectedPkp.tokenId
    );

    // If no tools with policies are found, log a message and return.
    if (Object.keys(registeredTools.toolsWithPolicies).length === 0) {
      logger.info('No registered tools with a policy for this PKP.');
      return;
    }

    const selectedTool = await promptSelectTool(
      Object.entries(registeredTools.toolsWithPolicies).map(([ipfsCid, tool]) => ({
        ...tool,
        ipfsCid,
      })),
      []
    );

    const policy = await awDelegatee.getToolPolicy(
      selectedPkp.tokenId,
      selectedTool.ipfsCid
    );

    const decodedPolicy = selectedTool.policy.decode(policy.policy);

    // Log the tool policy details.
    logger.info(
      `Tool Policy for PKP ${selectedPkp.tokenId} and Tool ${selectedTool.ipfsCid}:`
    );
    logger.log(`Version: ${policy.version}`);
    logger.log('Policy:');
    logger.log(JSON.stringify(decodedPolicy, null, 2));
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        logger.info('No PKP selected');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS) {
        logger.info('No known tools with policies available for the selected PKP');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_TOOL_CANCELLED) {
        logger.info('No tool selected');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_POLICY) {
        logger.info(error.message);
        return;
      }
    }

    // For any other errors, log them in a user-friendly way
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    logger.log(`Failed to get tool policy: ${errorMessage}`);
  }
};
