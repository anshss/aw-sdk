// Import the FssAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as FssAdmin } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import {
  promptConfirmPermit,
  promptSelectToolToPermit,
} from '../../prompts/admin/permit-tool';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the FssTool type from the '@lit-protocol/aw-tool' package.
import { FssTool } from '@lit-protocol/aw-tool';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Permits a tool in the Full Self-Signing (FSS) system.
 * This function prompts the user to confirm the action, permits the tool,
 * and logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param tool - The tool to permit.
 */
const permitTool = async (fssAdmin: FssAdmin, tool: FssTool) => {
  // Prompt the user to confirm the tool permitting action.
  await promptConfirmPermit(tool);

  // Log a loading message to indicate the operation is in progress.
  logger.loading('Permitting tool...');

  // Permit the tool in the FSS system.
  await fssAdmin.permitTool({ ipfsCid: tool.ipfsCid });

  // Log a success message once the tool is permitted.
  logger.success('Tool permitted successfully.');
};

/**
 * Handles the process of permitting a tool in the FSS system.
 * This function retrieves the list of already permitted tools, prompts the user to select a tool to permit,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handlePermitTool = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the list of already permitted tools.
    const alreadyPermittedTools = await handleGetTools(fssAdmin);

    // Prompt the user to select a tool to permit and permit it.
    await permitTool(
      fssAdmin,
      await promptSelectToolToPermit(fssAdmin.litNetwork, alreadyPermittedTools)
    );
  } catch (error) {
    // Handle specific errors related to tool permitting.
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS
      ) {
        // Log an error message if no unpermitted tools are found.
        logger.error('No unpermitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool permitting cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
