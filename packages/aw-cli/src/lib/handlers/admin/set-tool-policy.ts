// Import the AwTool, AwAdmin, and PermittedTools types from the '@lit-protocol/agent-wallet' package.
import type {
  AwTool,
  PkpInfo,
  Admin as AwAdmin,
  PermittedTools,
} from '@lit-protocol/agent-wallet';

// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

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
 * @throws AwCliError - If the user cancels the selection.
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
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  // Return the selected tool.
  return tool as AwTool;
};

/**
 * Prompts the user to select a delegatee for setting the tool policy.
 * This function throws an error if the user cancels the selection.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to get delegatees for.
 * @returns The selected delegatee address.
 * @throws AwCliError - If the user cancels the selection.
 */
const promptSelectDelegatee = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  // Get the list of delegatees
  const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

  if (delegatees.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES,
      'No delegatees found for this PKP.'
    );
  }

  // Prompt the user to select a delegatee
  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message: 'Select a delegatee to set the policy for:',
    choices: delegatees.map((address) => ({
      title: address,
      value: address,
    })),
  });

  // Throw an error if the user cancels the selection.
  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  return delegatee;
};

/**
 * Sets the policy for a selected tool in the Full Self-Signing (AW) system.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to set the tool policy for.
 * @param tool - The tool for which the policy will be set.
 * @param delegatee - The delegatee address to set the policy for.
 * @param policyIpfsCid - The IPFS CID of the policy to set.
 * @param policyParams - Optional policy parameters to set.
 */
const setToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: AwTool,
  delegatee: string,
  policyIpfsCid: string,
  policyParams?: Record<string, any>
) => {
  try {
    // Log a loading message to indicate the operation is in progress.
    logger.loading('Setting tool policy...');

    // Set the tool's policy in the AW system.
    await awAdmin.setToolPolicyForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee,
      policyIpfsCid || tool.defaultPolicyIpfsCid,
      true
    );

    // If there are policy parameters, set them
    if (policyParams) {
      logger.loading('Setting policy parameters...');
      const paramNames = Object.keys(policyParams).filter(name => name !== 'type' && name !== 'version');
      const paramValues = paramNames.map(name => policyParams[name]);
      await awAdmin.setToolPolicyParametersForDelegatee(
        pkp.info.tokenId,
        tool.ipfsCid,
        delegatee,
        paramNames,
        paramValues
      );
    }

    // Finally, permit the tool for the delegatee
    logger.loading('Permitting tool for delegatee...');
    await awAdmin.permitToolForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee
    );

    // Log a success message once the policy is set.
    logger.success('Tool policy set successfully.');
  } catch (error) {
    if (error instanceof Error) {
      logger.error(`Failed to set tool policy: ${error.message}`);
    } else {
      logger.error('Failed to set tool policy: Unknown error occurred');
    }
  }
};

/**
 * Handles the process of setting or updating a tool's policy in the AW system.
 * This function retrieves the list of permitted tools, prompts the user to select a tool,
 * collects policy details, sets the policy, and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to set the tool policy for.
 */
export const handleSetToolPolicy = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Retrieve the list of permitted tools.
    const permittedTools = await handleGetTools(awAdmin, pkp);

    // If no tools without policies are found, throw an error.
    if (
      permittedTools === null ||
      permittedTools.toolsWithoutPolicies.length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    // Prompt the user to select a tool for setting or updating its policy.
    const selectedTool = await promptSelectToolForPolicy(permittedTools);

    // Prompt the user to select a delegatee.
    const selectedDelegatee = await promptSelectDelegatee(awAdmin, pkp);

    // Prompt the user for policy details.
    const { policyIpfsCid, parameters } = await promptPolicyDetails(selectedTool);

    // Set the policy for the selected tool.
    await setToolPolicy(
      awAdmin,
      pkp,
      selectedTool,
      selectedDelegatee,
      policyIpfsCid || selectedTool.defaultPolicyIpfsCid,
      parameters
    );
  } catch (error) {
    // Handle specific errors related to tool policy setting.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES) {
        // Log an error message if no delegatees are found.
        logger.error('No delegatees found for this PKP.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy setting cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
