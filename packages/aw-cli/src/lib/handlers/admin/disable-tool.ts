// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import { promptSelectToolForPolicy } from '../../prompts/admin';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Disables a tool in the AW system.
 * This function prompts the user to select a tool and disables it.
 * Disabling a tool means it cannot be used right now, separate from policy-level enabling per delegatee.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to disable the tool for.
 */
export const handleDisableTool = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
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

    // Log a loading message to indicate the operation is in progress.
    logger.loading('Disabling tool...');

    try {
      // Disable the tool.
      await awAdmin.disableTool(pkp.info.tokenId, selectedTool.ipfsCid);

      // Log a success message once the tool is disabled.
      logger.success('Tool disabled successfully.');
      logger.info('The tool cannot be used by delegatees until it is enabled again.');
    } catch (error) {
      if (error instanceof Error) {
        logger.error(`Failed to disable tool: ${error.message}`);
      } else {
        logger.error('Failed to disable tool: Unknown error occurred');
      }
    }
  } catch (error) {
    // Handle specific errors related to tool disabling.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_PERMIT_TOOL_NO_TOOLS) {
        // Log an info message if no permitted tools are found.
        logger.info('No permitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an info message if the user cancels the operation.
        logger.info('Tool disabling cancelled.');
        return;
      }
    }

    // For any other errors, log them in a user-friendly way
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    logger.log(`Failed to disable tool: ${errorMessage}`);
  }
}; 