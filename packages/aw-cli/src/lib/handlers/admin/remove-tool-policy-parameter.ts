import type {
  PkpInfo,
  Admin as AwAdmin,
  RegisteredToolWithPolicies,
  RegisteredToolsResult,
} from '@lit-protocol/agent-wallet';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool for removing policy parameters.
 */
const promptSelectToolForPolicyParameter = async (
  registeredToolsResult: RegisteredToolsResult
) => {
  const choices = [
    ...Object.values(registeredToolsResult.toolsWithPolicies).map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'Remove policy parameters',
      value: tool,
    })),
  ];

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to remove policy parameters from:',
    choices,
  });

  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter removal cancelled.'
    );
  }

  return tool as RegisteredToolWithPolicies;
};

/**
 * Prompts the user to select a delegatee for removing policy parameters.
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
    message: 'Select a delegatee to remove policy parameters from:',
    choices,
  });

  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter removal cancelled.'
    );
  }

  return delegatee;
};

/**
 * Prompts the user to select parameters to remove.
 */
const promptParametersToRemove = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: RegisteredToolWithPolicies,
  delegatee: string
) => {
  // Get all parameters from chain
  const parameters = await awAdmin.getAllToolPolicyParametersForDelegatee(
    pkp.info.tokenId,
    tool.ipfsCid,
    delegatee
  );

  if (!parameters || parameters.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
      'No parameters found to remove.'
    );
  }

  const choices = parameters.map(
    (param: { name: string; value: Uint8Array }) => ({
      title: param.name,
      value: param.name,
    })
  );

  const { selectedParameters } = await prompts({
    type: 'multiselect',
    name: 'selectedParameters',
    message: 'Select parameters to remove (Space to select):',
    choices,
    min: 1,
    instructions: false,
  });

  if (!selectedParameters || selectedParameters.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter removal cancelled.'
    );
  }

  return selectedParameters as string[];
};

/**
 * Removes the selected tool policy parameters for a delegatee.
 */
const removeToolPolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: RegisteredToolWithPolicies,
  delegatee: string,
  parameterNames: string[]
) => {
  try {
    const receipt = await awAdmin.removeToolPolicyParametersForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee,
      parameterNames
    );

    logger.success(
      `Successfully removed ${parameterNames.length} policy parameter(s) for tool ${tool.name} (${tool.ipfsCid}) and delegatee ${delegatee}`
    );
    return receipt;
  } catch (err: any) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
      `Failed to remove tool policy parameters: ${err.message}`
    );
  }
};

export const handleRemoveToolPolicyParameter = async (
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

    // Get parameters to remove
    const parameterNames = await promptParametersToRemove(
      awAdmin,
      pkp,
      tool,
      delegatee
    );

    // Remove policy parameters
    await removeToolPolicyParameters(
      awAdmin,
      pkp,
      tool,
      delegatee,
      parameterNames
    );
  } catch (error) {
    // Handle specific errors related to tool policy parameter removal
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        logger.error('No tools with policies found.');
        return;
      }

      if (
        error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED
      ) {
        logger.error('Tool policy parameter removal cancelled.');
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
