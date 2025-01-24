import type {
  PkpInfo,
  Admin as AwAdmin,
  RegisteredToolWithPolicies,
  RegisteredToolsResult,
} from '@lit-protocol/agent-wallet';
import prompts from 'prompts';
import { ethers } from 'ethers';

import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool for viewing policy parameters.
 */
const promptSelectToolForPolicyParameter = async (
  registeredToolsResult: RegisteredToolsResult
) => {
  const choices = [
    ...Object.values(registeredToolsResult.toolsWithPolicies).map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'View policy parameters',
      value: tool,
    })),
  ];

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to view policy parameters for:',
    choices,
  });

  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter viewing cancelled.'
    );
  }

  return tool as RegisteredToolWithPolicies;
};

/**
 * Prompts the user to select a delegatee for viewing policy parameters.
 */
const promptSelectToolDelegateeForPolicyParameter = async (
  delegatees: string[]
) => {
  if (delegatees.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_NO_DELEGATEES,
      'No delegatees found.'
    );
  }

  const choices = delegatees.map((delegatee) => ({
    title: delegatee,
    value: delegatee,
  }));

  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message: 'Select a delegatee to view policy parameters for:',
    choices,
  });

  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter viewing cancelled.'
    );
  }

  return delegatee;
};

/**
 * Displays the tool policy parameters for a delegatee.
 */
const displayToolPolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: RegisteredToolWithPolicies,
  delegatee: string
) => {
  try {
    // Get all parameters from chain
    const parameters = await awAdmin.getAllToolPolicyParametersForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee
    );

    if (!parameters || parameters.length === 0) {
      logger.info('No parameters found.');
      return;
    }

    // Display parameters
    logger.info(
      `Policy parameters for tool ${tool.name} (${tool.ipfsCid}) and delegatee ${delegatee}:`
    );

    for (const param of parameters) {
      try {
        // Try to decode the value as UTF-8
        const value = Buffer.from(param.value).toString('utf8');
        let displayValue: string;

        // Try to parse as JSON if it looks like JSON
        if (value.startsWith('[') || value.startsWith('{')) {
          try {
            const parsed = JSON.parse(value);
            displayValue = JSON.stringify(parsed, null, 2);
          } catch {
            displayValue = value;
          }
        } else {
          displayValue = value;
        }

        logger.info(`${param.name}: ${displayValue}`);
      } catch (err) {
        // If UTF-8 decoding fails, show hex
        logger.info(`${param.name}: ${ethers.utils.hexlify(param.value)}`);
      }
    }
  } catch (err: any) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
      `Failed to get tool policy parameters: ${err.message}`
    );
  }
};

export const handleGetToolPolicyParameter = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  try {
    // Get registered tools
    const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(
      pkp.info.tokenId
    );

    // Check if there are any tools with policies
    if (
      registeredTools === null ||
      Object.keys(registeredTools.toolsWithPolicies).length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
        'No tools with policies found.'
      );
    }

    // Get tool with policies
    const tool = await promptSelectToolForPolicyParameter(registeredTools);

    // Get delegatee
    const delegatee = await promptSelectToolDelegateeForPolicyParameter(
      tool.delegatees
    );

    // Display policy parameters
    await displayToolPolicyParameters(awAdmin, pkp, tool, delegatee);
  } catch (error) {
    // Handle specific errors related to tool policy parameter viewing
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        logger.error('No tools with policies found.');
        return;
      }

      if (
        error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED
      ) {
        logger.error('Tool policy parameter viewing cancelled.');
        return;
      }

      if (
        error.type ===
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_NO_DELEGATEES
      ) {
        logger.error('No delegatees found for the selected tool.');
        return;
      }

      if (
        error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED
      ) {
        logger.error(error.message);
        return;
      }
    }

    // Re-throw any other errors
    throw error;
  }
};
