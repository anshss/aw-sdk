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
import { promptSelectDelegateeFromList } from '../../prompts/admin/select-delegatee-from-list';

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
 * This function logs the progress of the operation and handles cases where no tools are found.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to get the tool policy for.
 */
export const handleGetToolPolicy = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no tools with policies are found, log a message and return
    if (
      permittedTools === null ||
      permittedTools.toolsWithPolicies.length === 0
    ) {
      logger.info('No tools with policies found.');
      return;
    }

    // Prompt the user to select a tool.
    const selectedTool = await promptSelectToolForPolicy(
      permittedTools.toolsWithPolicies
    );

    // Get the list of delegatees.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // If no delegatees are found, log and return.
    if (!delegatees.length) {
      logger.info('No delegatees found for this PKP.');
      return;
    }

    // Prompt the user to select a delegatee.
    const selectedDelegatee = await promptSelectDelegateeFromList(delegatees, 'Select a delegatee to view policy for:');

    // Log a loading message to indicate the operation is in progress.
    logger.loading('Getting tool policy...');

    try {
      // Get the tool's policy from the AW system.
      const { policyIpfsCid, enabled } = await awAdmin.getToolPolicyForDelegatee(
        pkp.info.tokenId,
        selectedTool.ipfsCid,
        selectedDelegatee
      );

      if (!policyIpfsCid) {
        logger.info('No policy found for this tool and delegatee.');
        return;
      }

      // Log the tool policy details.
      logger.info(
        `Tool Policy for PKP ${pkp.info.tokenId} and Tool ${selectedTool.ipfsCid}:`
      );
      logger.log(`Policy IPFS CID: ${policyIpfsCid}`);
      logger.log(`Enabled: ${enabled}`);

      // Get and display policy parameters if they exist
      try {
        const parameters = await awAdmin.getToolPolicyParametersForDelegatee(
          pkp.info.tokenId,
          selectedTool.ipfsCid,
          selectedDelegatee,
          []
        );
        if (Object.keys(parameters).length > 0) {
          logger.log('\nPolicy Parameters:');
          logger.log(JSON.stringify(parameters, null, 2));
        }
      } catch (error) {
        logger.info('No policy parameters set for this tool and delegatee.');
      }
    } catch (error) {
      if (error instanceof Error) {
        logger.error(`Failed to get tool policy: ${error.message}`);
      } else {
        logger.error('Failed to get tool policy: Unknown error occurred');
      }
    }
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_GET_TOOL_POLICY_NO_TOOLS) {
        // Log an info message if no tools with policies are found.
        logger.info('No tools with policies found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED) {
        // Log an info message if the user cancels the operation.
        logger.info('Tool policy viewing cancelled.');
        return;
      }
    }

    // For any other errors, log them in a user-friendly way
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    logger.log(`Failed to get tool policy: ${errorMessage}`);
  }
};