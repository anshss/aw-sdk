// Import the AwAdmin and AwTool types from the '@lit-protocol/agent-wallet' package.
import type {
  PkpInfo,
  Admin as AwAdmin,
  AwTool,
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
 * Prompts the user to select a tool from a list of tools with policies.
 * This function throws an error if the user cancels the selection.
 *
 * @param toolsWithPolicies - An array of tools with policies.
 * @returns The selected tool.
 * @throws AwCliError - If the user cancels the selection.
 */
const promptSelectToolForPolicy = async (
  toolsWithPolicies: AwTool<any, any>[]
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
    throw new AwCliError(
      AwCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED,
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
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to get the tool policy for.
 * @param tool - The tool for which to retrieve the policy.
 */
const getToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: AwTool<any, any>
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting tool policy...');

  // Retrieve the tool's policy and version from the AW system.
  const { policy, version } = await awAdmin.getToolPolicy(
    pkp.info.tokenId,
    tool.ipfsCid
  );

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
 * @param awAdmin - An instance of the AwAdmin class.
 */
export const handleGetToolPolicy = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no permitted tools are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools?.toolsWithPolicies.length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool and retrieve its policy.
    await getToolPolicy(
      awAdmin,
      pkp,
      await promptSelectToolForPolicy(permittedTools.toolsWithPolicies)
    );
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools with policies found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy viewing cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
