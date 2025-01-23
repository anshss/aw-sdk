// Import the AwTool and AwAdmin types from the '@lit-protocol/agent-wallet' package.
import type {
  AwTool,
  Admin as AwAdmin,
  PkpInfo,
} from '@lit-protocol/agent-wallet';

// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the handleGetTools function to retrieve permitted tools.
import { handleGetTools } from './get-tools';

/**
 * Prompts the user to confirm the removal of a tool's policy.
 * This function throws an error if the user cancels the confirmation.
 *
 * @param tool - The tool for which the policy will be removed.
 * @throws AwCliError - If the user cancels the confirmation.
 */
const promptConfirmPolicyRemoval = async (tool: AwTool<any, any>) => {
  // Prompt the user to confirm the policy removal.
  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: `Are you sure you want to remove the policy for tool ${tool.name} (${tool.ipfsCid})?`,
    initial: false,
  });

  // Throw an error if the user cancels the confirmation.
  if (!confirmed) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED,
      'Tool policy removal cancelled.'
    );
  }
};

/**
 * Prompts the user to select a tool for policy removal and confirms the action.
 * This function throws an error if the user cancels the selection or confirmation.
 *
 * @param toolsWithPolicies - An array of tools with policies.
 * @returns The selected tool.
 * @throws AwCliError - If the user cancels the selection or confirmation.
 */
const promptSelectToolForPolicyRemoval = async (
  toolsWithPolicies: AwTool<any, any>[]
) => {
  // Map the tools to a list of choices for the prompts library.
  const choices = toolsWithPolicies.map((tool) => ({
    title: `${tool.name} (${tool.ipfsCid})`,
    value: tool,
  }));

  // Prompt the user to select a tool for policy removal.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to remove policy:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED,
      'Tool policy removal cancelled.'
    );
  }

  // Confirm the policy removal with the user.
  await promptConfirmPolicyRemoval(tool);

  // Return the selected tool.
  return tool;
};

/**
 * Removes the policy for a selected tool in the Full Self-Signing (AW) system.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the tool policy for.
 * @param tool - The tool for which the policy will be removed.
 */
const removeToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: AwTool<any, any>
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing tool policy...');

  // Remove the tool's policy from the AW system.
  await awAdmin.removeToolPolicy(pkp.info.tokenId, tool.ipfsCid);

  // Log a success message once the policy is removed.
  logger.success('Tool policy removed successfully.');
};

/**
 * Handles the process of removing a tool's policy in the AW system.
 * This function retrieves the list of permitted tools, prompts the user to select a tool,
 * confirms the action, removes the policy, and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the tool policy for.
 */
export const handleRemoveToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no tools with policies are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools.toolsWithPolicies.length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS,
        'No tools with policies found.'
      );
    }

    // Prompt the user to select a tool for policy removal and remove the policy.
    await removeToolPolicy(
      awAdmin,
      pkp,
      await promptSelectToolForPolicyRemoval(permittedTools.toolsWithPolicies)
    );
  } catch (error) {
    // Handle specific errors related to tool policy removal.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no tools with policies are found.
        logger.error('No tools with policies found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy removal cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
