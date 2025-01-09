// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import types and utilities from the '@lit-protocol/agent-wallet' package.
import {
  listToolsByNetwork,
  type AwTool,
  type LitNetwork,
  type PermittedTools,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool to permit, filtering out already permitted tools.
 * This function retrieves the list of available tools for the specified Lit network,
 * filters out tools that are already permitted, and prompts the user to select a tool.
 *
 * @param litNetwork - The Lit network for which to retrieve available tools.
 * @param alreadyPermittedTools - An object containing tools that are already permitted.
 * @returns The selected tool to permit.
 * @throws AwCliError - If no unpermitted tools are found or the user cancels the selection.
 */
export const promptSelectToolToPermit = async (
  litNetwork: LitNetwork,
  alreadyPermittedTools: PermittedTools | null
) => {
  // Retrieve the list of available tools for the specified Lit network.
  const availableTools = listToolsByNetwork(litNetwork);

  // Create a set of IPFS CIDs for already permitted tools for efficient lookup.
  const permittedCids = new Set([
    ...(alreadyPermittedTools?.toolsWithPolicies.map(
      (tool: AwTool<any, any>) => tool.ipfsCid
    ) || []),
    ...(alreadyPermittedTools?.toolsWithoutPolicies.map(
      (tool: AwTool<any, any>) => tool.ipfsCid
    ) || []),
  ]);

  // Filter out tools that are already permitted.
  const unpermittedTools = availableTools.filter(
    (tool: AwTool<any, any>) => !permittedCids.has(tool.ipfsCid)
  );

  // If no unpermitted tools are found, throw an error.
  if (unpermittedTools.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS,
      'No unpermitted tools found.'
    );
  }

  // Prompt the user to select a tool to permit.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to permit:',
    choices: unpermittedTools.map((tool: AwTool<any, any>) => ({
      title: tool.name,
      description: tool.description,
      value: tool,
    })),
  });

  // If the user cancels the selection, throw an error.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool permitting cancelled.'
    );
  }

  // Return the selected tool.
  return tool as AwTool<any, any>;
};

/**
 * Prompts the user to confirm the tool permitting action.
 * This function displays details of the selected tool and asks the user to confirm the action.
 *
 * @param tool - The tool to permit.
 * @returns A boolean indicating whether the user confirmed the action.
 * @throws AwCliError - If the user cancels the confirmation.
 */
export const promptConfirmPermit = async (tool: AwTool) => {
  // Display details of the selected tool.
  logger.log('');
  logger.log(`Name: ${tool.name}`);
  logger.log(`Description: ${tool.description}`);
  logger.log(`IPFS CID: ${tool.ipfsCid}`);
  logger.log('');

  // Prompt the user to confirm the tool permitting action.
  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Are you sure you want to permit this tool?',
    initial: true,
  });

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool permitting cancelled.'
    );
  }

  // Return the confirmation status.
  return confirmed;
};
