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
 * Prompts the user to select a tool for setting policy parameters.
 */
const promptSelectToolForPolicyParameter = async (
  registeredToolsResult: RegisteredToolsResult
) => {
  const choices = [
    ...Object.values(registeredToolsResult.toolsWithPolicies).map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      description: 'Set policy parameters',
      value: tool,
    })),
  ];

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to set policy parameters for:',
    choices,
  });

  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter setting cancelled.'
    );
  }

  return tool as RegisteredToolWithPolicies;
};

/**
 * Prompts the user to select a delegatee for setting policy parameters.
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
    message: 'Select a delegatee to set policy parameters for:',
    choices,
  });

  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter setting cancelled.'
    );
  }

  return delegatee;
};

/**
 * Prompts the user to enter policy parameter name and value.
 * Returns null if user enters nothing for parameter name.
 */
const promptPolicyParameter = async (
  existingParameters: { name: string; value: Uint8Array }[]
) => {
  // Display existing parameters if any
  if (existingParameters.length > 0) {
    logger.info('Existing parameters:');
    for (const param of existingParameters) {
      try {
        const value = Buffer.from(param.value).toString('utf8');
        let displayValue: string;

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
      } catch {
        logger.info(`${param.name}: ${ethers.utils.hexlify(param.value)}`);
      }
    }
  }

  const { parameterName } = await prompts({
    type: 'text',
    name: 'parameterName',
    message: 'Enter parameter name (leave empty to finish):',
  });

  if (!parameterName) {
    return null;
  }

  // Check if parameter name already exists
  if (existingParameters.some((p) => p.name === parameterName)) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
      `Parameter "${parameterName}" already exists. Please remove it first if you want to update it.`
    );
  }

  const { parameterType } = await prompts({
    type: 'select',
    name: 'parameterType',
    message: 'Select parameter type:',
    choices: [
      { title: 'Number - Integer or Decimal', value: 'number' },
      { title: 'Address - Single Ethereum Address', value: 'address' },
      { title: 'Addresses - Array of Ethereum Addresses', value: 'address[]' },
      { title: 'Text - String Value', value: 'string' },
      { title: 'Boolean - True/False', value: 'boolean' },
    ],
  });

  if (!parameterType) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter setting cancelled.'
    );
  }

  const { parameterValue } = await prompts({
    type: 'text',
    name: 'parameterValue',
    message: `Enter parameter value (${parameterType}):`,
  });

  if (!parameterValue) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED,
      'Tool policy parameter setting cancelled.'
    );
  }

  try {
    let processedValue: string;

    switch (parameterType) {
      case 'number': {
        // Validate number
        const num = Number(parameterValue);
        if (isNaN(num)) {
          throw new Error('Invalid number format');
        }
        processedValue = parameterValue;
        break;
      }
      case 'address': {
        // Validate address
        processedValue = ethers.utils.getAddress(parameterValue);
        break;
      }
      case 'address[]': {
        // Split comma-separated addresses, validate each one
        const addresses = parameterValue
          .split(',')
          .map((addr: string) => addr.trim())
          .map((addr: string) => ethers.utils.getAddress(addr));
        processedValue = JSON.stringify(addresses);
        break;
      }
      case 'boolean': {
        const boolValue =
          parameterValue.toLowerCase() === 'true' || parameterValue === '1';
        processedValue = boolValue.toString();
        break;
      }
      case 'string':
      default:
        processedValue = parameterValue;
    }

    return {
      name: parameterName,
      value: ethers.utils.toUtf8Bytes(processedValue),
    };
  } catch (err) {
    if (err instanceof Error) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
        `Failed to process parameter value: ${err.message}`
      );
    }
    throw err;
  }
};

/**
 * Sets the tool policy parameters for a delegatee.
 */
const setToolPolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  tool: RegisteredToolWithPolicies,
  delegatee: string
) => {
  // Get existing parameters from chain
  let existingParameters: { name: string; value: Uint8Array }[] = [];
  try {
    existingParameters = await awAdmin.getAllToolPolicyParametersForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee
    );
  } catch (err) {
    // Ignore errors getting existing parameters
    logger.warn('Failed to get existing parameters');
  }

  const parameterNames: string[] = [];
  const parameterValues: Uint8Array[] = [];

  while (true) {
    const parameter = await promptPolicyParameter(existingParameters);
    if (!parameter) {
      break;
    }
    parameterNames.push(parameter.name);
    parameterValues.push(parameter.value);
  }

  if (parameterNames.length === 0) {
    logger.info('No parameters to set.');
    return;
  }

  try {
    const receipt = await awAdmin.setToolPolicyParametersForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee,
      parameterNames,
      parameterValues
    );

    logger.success(
      `Successfully set ${parameterNames.length} policy parameter(s) for tool ${tool.name} (${tool.ipfsCid}) and delegatee ${delegatee}`
    );
    return receipt;
  } catch (err: any) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_FAILED,
      `Failed to set tool policy parameters: ${err.message}`
    );
  }
};

export const handleSetToolPolicyParameter = async (
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

    // Set policy parameters
    await setToolPolicyParameters(awAdmin, pkp, tool, delegatee);
  } catch (error) {
    // Handle specific errors related to tool policy parameter setting
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        logger.error('No tools with policies found.');
        return;
      }

      if (
        error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_PARAMETER_CANCELLED
      ) {
        logger.error('Tool policy parameter setting cancelled.');
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
