// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import { promptSelectToolForPolicy, promptSelectDelegatee } from '../../prompts/admin';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Enables a tool policy for a specific delegatee in the AW system.
 * This function prompts the user to select a tool and delegatee, then enables the tool policy.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to enable the tool policy for.
 */
export const handleEnableToolPolicy = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no tools with policies are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools.toolsWithPolicies.length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS,
        'No tools with policies found.'
      );
    }

    // Prompt the user to select a tool.
    const selectedTool = await promptSelectToolForPolicy(permittedTools);

    // Prompt the user to select a delegatee.
    const selectedDelegatee = await promptSelectDelegatee(awAdmin, pkp);

    // Log a loading message to indicate the operation is in progress.
    logger.loading('Enabling tool policy...');

    // Enable the tool policy.
    await awAdmin.enableToolPolicyForDelegatee(
      pkp.info.tokenId,
      selectedTool.ipfsCid,
      selectedDelegatee
    );

    // Log a success message once the policy is enabled.
    logger.success('Tool policy enabled successfully.');
  } catch (error) {
    // Handle specific errors related to policy enabling.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no tools with policies are found.
        logger.error('No tools with policies found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES) {
        // Log an error message if no delegatees are found.
        logger.error('No delegatees found for this PKP.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy enabling cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
}; 