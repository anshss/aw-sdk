// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import types from the '@lit-protocol/full-self-signing' package.
import type { PermittedTools, FssTool } from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool to remove from a list of permitted tools.
 * This function ensures that a tool is selected before proceeding. If no tool is selected,
 * the function throws an error.
 *
 * @param alreadyPermittedTools - An object containing tools that are already permitted.
 * @returns The selected tool to remove.
 * @throws FssCliError - If no permitted tools are found or the user cancels the selection.
 */
export const promptSelectToolForRemoval = async (
  alreadyPermittedTools: PermittedTools
): Promise<FssTool<any, any>> => {
  // Combine tools with and without policies into a single list of choices.
  const choices = [
    ...alreadyPermittedTools.toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
    })),
    ...alreadyPermittedTools.toolsWithoutPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
    })),
  ];

  // If no permitted tools are found, throw an error.
  if (choices.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
      'No permitted tools found.'
    );
  }

  // Prompt the user to select a tool to remove.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to remove:',
    choices,
  });

  // If no tool is selected, throw an error.
  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }

  // Return the selected tool.
  return tool;
};

/**
 * Prompts the user to confirm the removal of a selected tool.
 * This function displays details of the selected tool and asks the user to confirm the action.
 *
 * @param tool - The tool to remove.
 * @throws FssCliError - If the user cancels the confirmation.
 */
export const promptConfirmRemoval = async (tool: FssTool<any, any>) => {
  // Display details of the selected tool.
  logger.log('');
  logger.log(`${tool.name} (${tool.ipfsCid})`);
  logger.log('');

  // Prompt the user to confirm the tool removal action.
  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Are you sure you want to remove this tool?',
    initial: false,
  });

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }
};
