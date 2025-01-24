// Import the AwTool, AwAdmin, and PermittedTools types from the '@lit-protocol/agent-wallet' package.
import type {
  PkpInfo,
  Admin as AwAdmin,
  RegisteredToolWithPolicies,
  RegisteredToolsResult,
  ToolMetadata,
} from '@lit-protocol/agent-wallet';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool for setting or updating its policy.
 * This function throws an error if the user cancels the selection.
 *
 * @param permittedTools - An object containing tools with and without policies.
 * @returns The selected tool.
 * @throws AwCliError - If the user cancels the selection.
 */
const promptSelectToolForPolicy = async (
  registeredToolsResult: RegisteredToolsResult
) => {
  // Combine tools with and without policies into a single list of choices.
  const choices = [
    ...Object.values(registeredToolsResult.toolsWithPolicies).map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'Update existing policy',
      value: tool,
    })),
    ...Object.values(registeredToolsResult.toolsWithoutPolicies).map(
      (tool) => ({
        title: `${tool.name} (${tool.ipfsCid})`,
        description: 'Set new policy',
        value: tool,
      })
    ),
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
  return tool as RegisteredToolWithPolicies | ToolMetadata;
};

/**
 * Prompts the user to select a delegatee for a tool from a list of delegatees.
 * This function throws an error if the user cancels the selection.
 *
 * @param delegatees - An array of delegatee addresses.
 * @returns The selected delegatee address.
 * @throws AwCliError - If the user cancels the selection.
 */
const promptSelectToolDelegateeForPolicy = async (delegatees: string[]) => {
  if (delegatees.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES,
      'No delegatees found.'
    );
  }

  // Map the delegatees to a list of choices for the prompts library.
  const choices = delegatees.map((delegatee) => ({
    title: delegatee,
    value: delegatee,
  }));

  // Prompt the user to select a delegatee.
  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message: 'Select a delegatee to set the policy for:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_GET_TOOL_POLICY_CANCELLED,
      'Tool policy viewing cancelled.'
    );
  }

  // Return the selected delegatee.
  return delegatee;
};

/**
 * Prompts the user to enter the IPFS CID for the policy.
 * This function validates the input to ensure it is a valid IPFS CID.
 *
 * @returns The entered IPFS CID.
 * @throws AwCliError - If the user cancels the input or provides invalid input.
 */
const promptPolicyIpfsCid = async () => {
  const { policyIpfsCid } = await prompts({
    type: 'text',
    name: 'policyIpfsCid',
    message: 'Enter the IPFS CID for the policy:',
  });

  // If the user cancels the input, throw an error.
  if (!policyIpfsCid) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  // Return the entered IPFS CID.
  return policyIpfsCid;
};

/**
 * Sets the policy for a selected tool in the Full Self-Signing (AW) system.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param tool - The tool for which the policy will be set.
 * @param policy - The policy to set for the tool.
 * @param version - The version of the policy.
 */
const setToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: RegisteredToolWithPolicies | ToolMetadata,
  delegatee: string,
  policyIpfsCid: string
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Setting tool policy...');

  // Set the tool's policy in the AW system.
  await awAdmin.setToolPolicyForDelegatee(
    pkp.info.tokenId,
    tool.ipfsCid,
    delegatee,
    policyIpfsCid,
    true
  );

  // Log a success message once the policy is set.
  logger.success('Tool policy set successfully.');
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
    const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(
      pkp.info.tokenId
    );

    // If no tools without policies are found, throw an error.
    if (
      registeredTools === null ||
      (Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
        Object.keys(registeredTools.toolsWithoutPolicies).length === 0)
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    const pkpDelegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    if (pkpDelegatees.length === 0) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES,
        'No delegatees found.'
      );
    }

    // Prompt the user to select a tool for setting or updating its policy.
    const selectedTool = await promptSelectToolForPolicy(registeredTools);

    const delegateesWithoutPolicy = [];
    for (const delegatee of pkpDelegatees) {
      const delegateePermittedTools =
        await awAdmin.getPermittedToolsForDelegatee(
          pkp.info.tokenId,
          delegatee
        );

      if (
        delegateePermittedTools.some(
          (tool) => tool.toolIpfsCid === selectedTool.ipfsCid
        ) &&
        !selectedTool.delegatees.includes(delegatee)
      ) {
        delegateesWithoutPolicy.push(delegatee);
      }
    }

    const delegatee = await promptSelectToolDelegateeForPolicy(
      delegateesWithoutPolicy
    );

    // Prompt the user for policy details.
    const policyIpfsCid = await promptPolicyIpfsCid();

    // Set the policy for the selected tool.
    await setToolPolicy(awAdmin, pkp, selectedTool, delegatee, policyIpfsCid);
  } catch (error) {
    // Handle specific errors related to tool policy setting.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Tool policy setting cancelled.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES) {
        // Log an error message if no delegatees are found.
        logger.error('No delegatees found for the selected tool.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
