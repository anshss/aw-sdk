// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import {
  promptConfirmPermit,
  promptSelectToolToPermit,
} from '../../prompts/admin/permit-tool';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the AwTool type from the '@lit-protocol/aw-tool' package.
import { AwTool } from '@lit-protocol/aw-tool';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Permits a tool in the Full Self-Signing (AW) system.
 * This function prompts the user to confirm the action, permits the tool,
 * and logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param tool - The tool to permit.
 */
const permitTool = async (awAdmin: AwAdmin, pkp: PkpInfo, tool: AwTool) => {
  // Prompt the user to confirm the tool permitting action.
  await promptConfirmPermit(tool);

  // Log a loading message to indicate the operation is in progress.
  logger.loading('Registering tool...');

  // Register the tool in the AW system.
  await awAdmin.registerTool(pkp.info.tokenId, tool.ipfsCid);

  // Log a success message once the tool is permitted.
  logger.success('Tool registered successfully.');
};

/**
 * Handles the process of permitting a tool in the AW system.
 * This function retrieves the list of already permitted tools, prompts the user to select a tool to permit,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 */
export const handlePermitTool = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of already permitted tools.
    const alreadyPermittedTools = await handleGetTools(awAdmin, pkp);

    // Prompt the user to select a tool to permit and permit it.
    await permitTool(
      awAdmin,
      pkp,
      await promptSelectToolToPermit(awAdmin.litNetwork, alreadyPermittedTools)
    );
  } catch (error) {
    // Handle specific errors related to tool permitting.
    if (error instanceof AwCliError) {
      if (
        error.type === AwCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS
      ) {
        // Log an error message if no unpermitted tools are found.
        logger.error('No unpermitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool permitting cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
