// Import the FssTool, FssAdmin, and PermittedTools types from the '@lit-protocol/full-self-signing' package.
import {
  FssTool,
  type Admin as FssAdmin,
  type PermittedTools,
} from '@lit-protocol/full-self-signing';

// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

// Import the prompt utility for collecting policy details.
import { promptPolicyDetails } from '../../prompts/admin';

/**
 * Prompts the user to select a tool for setting or updating its policy.
 * This function throws an error if the user cancels the selection.
 *
 * @param permittedTools - An object containing tools with and without policies.
 * @returns The selected tool.
 * @throws FssCliError - If the user cancels the selection.
 */
const promptSelectToolForPolicy = async (permittedTools: PermittedTools) => {
  // Combine tools with and without policies into a single list of choices.
  const choices = [
    ...permittedTools.toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'Update existing policy',
      value: tool,
    })),
    ...permittedTools.toolsWithoutPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'Set new policy',
      value: tool,
    })),
  ];

  // Prompt the user to select a tool.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to set the policy for:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  // Return the selected tool.
  return tool as FssTool<any, any>;
};

/**
 * Sets the policy for a selected tool in the Full Self-Signing (FSS) system.
 * This function logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param tool - The tool for which the policy will be set.
 * @param policy - The policy to set for the tool.
 * @param version - The version of the policy.
 */
const setToolPolicy = async (
  fssAdmin: FssAdmin,
  tool: FssTool<any, any>,
  policy: string,
  version: string
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Setting tool policy...');

  // Set the tool's policy in the FSS system.
  await fssAdmin.setToolPolicy(tool.ipfsCid, policy, version);

  // Log a success message once the policy is set.
  logger.success('Tool policy set successfully.');
};

/**
 * Handles the process of setting or updating a tool's policy in the FSS system.
 * This function retrieves the list of permitted tools, prompts the user to select a tool,
 * collects policy details, sets the policy, and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleSetToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(fssAdmin);

    // If no tools without policies are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools.toolsWithoutPolicies.length === 0
    ) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool for setting or updating its policy.
    const selectedTool = await promptSelectToolForPolicy(permittedTools);

    // Prompt the user for policy details.
    const { policy, version } = await promptPolicyDetails(selectedTool);

    // Set the policy for the selected tool.
    await setToolPolicy(fssAdmin, selectedTool, policy, version);
  } catch (error) {
    // Handle specific errors related to tool policy setting.
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy setting cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
