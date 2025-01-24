// Import the AwAdmin and AwTool types from the '@lit-protocol/agent-wallet' package.
import type {
  PkpInfo,
  Admin as AwAdmin,
  AwTool,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import prompt utilities for user interaction.
import {
  promptConfirmRemoval,
  promptSelectToolForRemoval,
} from '../../prompts/admin/remove-tool';

/**
 * Removes a tool from the Full Self-Signing (AW) system.
 * This function prompts the user to confirm the action, removes the tool,
 * and logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the tool from.
 * @param tool - The tool to remove.
 */
const removeTool = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: AwTool<any, any>
) => {
  // Prompt the user to confirm the tool removal action.
  await promptConfirmRemoval(tool);

  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing tool...');

  // Remove the tool from the AW system.
  await awAdmin.removeTool(pkp.info.tokenId, tool.ipfsCid);

  // Log a success message once the tool is removed.
  logger.success('Tool removed successfully.');
};

/**
 * Handles the process of removing a tool from the AW system.
 * This function retrieves the list of permitted tools, prompts the user to select a tool to remove,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 */
export const handleRemoveTool = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(
      pkp.info.tokenId
    );

    // If no permitted tools are found, throw an error.
    if (
      registeredTools === null ||
      (Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
        Object.keys(registeredTools.toolsWithoutPolicies).length === 0)
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool to remove and remove it.
    await removeTool(
      awAdmin,
      pkp,
      await promptSelectToolForRemoval(registeredTools)
    );
  } catch (error) {
    // Handle specific errors related to tool removal.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool removal cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
