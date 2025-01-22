// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import {
  promptSelectToolForPolicy,
  promptSelectDelegatee,
} from '../../prompts/admin';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Unpermits a tool for a specific delegatee in the AW system.
 * This function prompts the user to select a tool and delegatee, then unpermits the tool for that delegatee.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to unpermit the tool for.
 */
export const handleUnpermitToolForDelegatee = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no tools are found, log a message and return
    if (
      permittedTools === null ||
      (permittedTools.toolsWithPolicies.length === 0 &&
        permittedTools.toolsWithoutPolicies.length === 0)
    ) {
      logger.info('No tools are currently permitted.');
      return;
    }

    // Prompt the user to select a tool.
    const selectedTool = await promptSelectToolForPolicy(permittedTools);

    // Prompt the user to select a delegatee.
    const selectedDelegatee = await promptSelectDelegatee(awAdmin, pkp);

    // Log a loading message to indicate the operation is in progress.
    logger.loading('Unpermitting tool for delegatee...');

    try {
      // Unpermit the tool for the delegatee.
      await awAdmin.unpermitToolForDelegatee(
        pkp.info.tokenId,
        selectedTool.ipfsCid,
        selectedDelegatee
      );

      // Log a success message once the tool is unpermitted.
      logger.success('Tool unpermitted successfully for delegatee.');
      logger.info('The delegatee can no longer use this tool.');
    } catch (error) {
      if (error instanceof Error) {
        logger.error(`Failed to unpermit tool for delegatee: ${error.message}`);
      } else {
        logger.error('Failed to unpermit tool for delegatee: Unknown error occurred');
      }
    }
  } catch (error) {
    // Handle specific errors related to tool unpermitting.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_PERMIT_TOOL_NO_TOOLS) {
        // Log an info message if no permitted tools are found.
        logger.info('No permitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES) {
        // Log an info message if no delegatees are found.
        logger.info('No delegatees found for this PKP.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an info message if the user cancels the operation.
        logger.info('Tool unpermitting cancelled.');
        return;
      }
    }

    // For any other errors, log them in a user-friendly way
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    logger.log(`Failed to unpermit tool for delegatee: ${errorMessage}`);
  }
}; 