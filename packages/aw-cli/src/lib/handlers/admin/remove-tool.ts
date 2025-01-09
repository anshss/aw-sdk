// Import the FssAdmin and FssTool types from the '@lit-protocol/agent-wallet' package.
import {
  type Admin as FssAdmin,
  type FssTool,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import prompt utilities for user interaction.
import {
  promptConfirmRemoval,
  promptSelectToolForRemoval,
} from '../../prompts/admin/remove-tool';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Removes a tool from the Full Self-Signing (FSS) system.
 * This function prompts the user to confirm the action, removes the tool,
 * and logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param tool - The tool to remove.
 */
const removeTool = async (fssAdmin: FssAdmin, tool: FssTool<any, any>) => {
  // Prompt the user to confirm the tool removal action.
  await promptConfirmRemoval(tool);

  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing tool...');

  // Remove the tool from the FSS system.
  await fssAdmin.removeTool(tool.ipfsCid);

  // Log a success message once the tool is removed.
  logger.success('Tool removed successfully.');
};

/**
 * Handles the process of removing a tool from the FSS system.
 * This function retrieves the list of permitted tools, prompts the user to select a tool to remove,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleRemoveTool = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(fssAdmin);

    // If no permitted tools are found, throw an error.
    if (
      permittedTools === null ||
      (permittedTools.toolsWithPolicies.length === 0 &&
        permittedTools.toolsWithoutPolicies.length === 0)
    ) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool to remove and remove it.
    await removeTool(
      fssAdmin,
      await promptSelectToolForRemoval(permittedTools)
    );
  } catch (error) {
    // Handle specific errors related to tool removal.
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool removal cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
