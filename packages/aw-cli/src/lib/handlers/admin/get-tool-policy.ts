// Import the FssAdmin and FssTool types from the '@lit-protocol/agent-wallet' package.
import {
  type Admin as FssAdmin,
  type FssTool,
} from '@lit-protocol/agent-wallet';

// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Prompts the user to select a tool from a list of tools with policies.
 * This function throws an error if the user cancels the selection.
 *
 * @param toolsWithPolicies - An array of tools with policies.
 * @returns The selected tool.
 * @throws FssCliError - If the user cancels the selection.
 */
const promptSelectToolForPolicy = async (
  toolsWithPolicies: FssTool<any, any>[]
) => {
  // Map the tools to a list of choices for the prompts library.
  const choices = toolsWithPolicies.map((tool) => ({
    title: `${tool.name} (${tool.ipfsCid})`,
    value: tool,
  }));

  // Prompt the user to select a tool.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to view policy:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED,
      'Tool policy viewing cancelled.'
    );
  }

  // Return the selected tool.
  return tool;
};

/**
 * Retrieves and displays the policy for a selected tool.
 * This function logs the tool's name, IPFS CID, policy version, and decoded policy.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param tool - The tool for which to retrieve the policy.
 */
const getToolPolicy = async (fssAdmin: FssAdmin, tool: FssTool<any, any>) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting tool policy...');

  // Retrieve the tool's policy and version from the FSS system.
  const { policy, version } = await fssAdmin.getToolPolicy(tool.ipfsCid);

  // Log the tool's name, IPFS CID, policy version, and decoded policy.
  logger.info('Tool Policy:');
  logger.log(`${tool.name} (${tool.ipfsCid})`);
  logger.log(`Version: ${version}`);
  const decodedPolicy = tool.policy.decode(policy);
  logger.log(`Policy: ${JSON.stringify(decodedPolicy, null, 2)}`);
};

/**
 * Handles the process of retrieving and displaying a tool's policy.
 * This function retrieves the list of permitted tools, prompts the user to select a tool,
 * and displays the tool's policy. It also handles errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleGetToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(fssAdmin);

    // If no permitted tools are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools?.toolsWithPolicies.length === 0
    ) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool and retrieve its policy.
    await getToolPolicy(
      fssAdmin,
      await promptSelectToolForPolicy(permittedTools.toolsWithPolicies)
    );
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools with policies found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy viewing cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
