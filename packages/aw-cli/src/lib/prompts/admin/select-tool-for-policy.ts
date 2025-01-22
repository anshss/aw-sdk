// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the AwTool type from the '@lit-protocol/agent-wallet' package.
import { type AwTool } from '@lit-protocol/agent-wallet';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the PermittedTools type
import { type PermittedTools } from '../../handlers/admin/get-tools';

/**
 * Prompts the user to select a tool for policy management.
 * This function displays a list of tools and allows the user to select one.
 *
 * @param tools - The list of tools to choose from.
 * @returns The selected tool.
 * @throws AwCliError - If the user cancels the selection.
 */
export const promptSelectToolForPolicy = async (tools: PermittedTools): Promise<AwTool> => {
  // Create choices from tools with and without policies
  const choices = [
    ...tools.toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (has policy)`,
      value: tool,
    })),
    ...tools.toolsWithoutPolicies.map((tool) => ({
      title: tool.name,
      value: tool,
    })),
  ];

  // If no tools are found, throw an error.
  if (choices.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
      'No tools found.'
    );
  }

  // Prompt the user to select a tool.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool:',
    choices,
  });

  // If the user cancels the selection, throw an error.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool selection cancelled.'
    );
  }

  return tool;
}; 