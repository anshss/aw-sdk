import prompts from 'prompts';
import { type AwTool } from '@lit-protocol/agent-wallet';
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool from a combined list of tools with and without policies.
 * Each tool is displayed with its name and IPFS CID. Tools with policies are marked as having a policy.
 *
 * @param toolsWithPolicies - An array of `AwTool` objects that have associated policies.
 * @param toolsWithoutPolicies - An array of `AwTool` objects that do not have associated policies.
 * @returns A promise that resolves to the selected `AwTool` object.
 * @throws {AwCliError} If no tools are available to select, an error of type `DELEGATEE_SELECT_TOOL_NO_TOOLS` is thrown.
 * @throws {AwCliError} If the user cancels the selection or no tool is selected, an error of type `DELEGATEE_SELECT_TOOL_CANCELLED` is thrown.
 */
export const promptSelectTool = async (
  toolsWithPolicies: AwTool<any, any>[],
  toolsWithoutPolicies: AwTool<any, any>[]
) => {
  // Combine tools with and without policies into a single list, marking whether each tool has a policy.
  const allTools = [
    ...toolsWithPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`, // Display the tool's name and IPFS CID.
      value: tool, // The tool object itself.
      hasPolicy: true, // Indicate that this tool has a policy.
    })),
    ...toolsWithoutPolicies.map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`, // Display the tool's name and IPFS CID.
      value: tool, // The tool object itself.
      hasPolicy: false, // Indicate that this tool does not have a policy.
    })),
  ];

  // If no tools are available, throw an error.
  if (allTools.length === 0) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
      'No tools available to select'
    );
  }

  // Prompt the user to select a tool from the combined list.
  const { tool } = await prompts({
    type: 'select', // Use a select input type for the menu.
    name: 'tool', // The name of the selected tool.
    message: 'Select a tool:', // The message displayed to the user.
    choices: allTools, // The list of available tools.
  });

  // If no tool is selected, throw an error.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_SELECT_TOOL_CANCELLED,
      'No tool selected'
    );
  }

  // Return the selected tool.
  return tool as AwTool<any, any>;
};
