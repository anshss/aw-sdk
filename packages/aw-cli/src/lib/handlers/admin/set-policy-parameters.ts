// Import the Admin class and necessary types.
import { Admin as AwAdmin, PkpInfo } from '@lit-protocol/agent-wallet';
// Import ethers for bytes conversion.
import { ethers } from 'ethers';
// Import prompts and utilities.
import { promptSelectToolForPolicy } from '../../prompts/admin/select-tool-for-policy';
import { promptSelectDelegateeFromList } from '../../prompts/admin/select-delegatee-from-list';
import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';
import prompts from 'prompts';
import { z } from 'zod';

// Import the function to get tools.
import { handleGetTools } from './get-tools';

/**
 * Prompts the user to enter values for an array field in a policy.
 */
const promptArrayValues = async (
  fieldName: string,
  schema: z.ZodType
): Promise<string[]> => {
  const values: string[] = [];

  logger.info(`Entering values for ${fieldName}:`);
  logger.log('(Press Enter without a value when done)\n');

  while (true) {
    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: `Enter value for ${fieldName} (${values.length + 1}):`,
      validate: (input) => {
        if (!input) return true;
        try {
          schema.parse(input);
          return true;
        } catch (error) {
          if (error instanceof z.ZodError) {
            return `Invalid input: ${error.errors[0]?.message}`;
          }
          return 'Invalid input';
        }
      },
    });

    if (!value) {
      if (values.length === 0) {
        const { confirmed } = await prompts({
          type: 'confirm',
          name: 'confirmed',
          message: 'No values entered. Do you want to leave this array empty?',
          initial: false,
        });
        if (confirmed) break;
        continue;
      }
      break;
    }

    values.push(value);
    logger.success(`Added: ${value}`);
  }

  return values;
};

/**
 * Converts a parameter value to bytes based on its type and schema
 */
function convertValueToBytes(name: string, value: unknown, schema: z.ZodType): string {
  // Skip type and version fields as they are handled by the policy itself
  if (name === 'type' || name === 'version') {
    return value as string;
  }

  // For arrays, handle each element appropriately
  if (schema instanceof z.ZodArray) {
    const arrayValue = value as unknown[];
    // For arrays of addresses, concatenate them
    if (arrayValue.every((v: unknown) => typeof v === 'string' && v.startsWith('0x'))) {
      return ethers.utils.hexlify(
        ethers.utils.concat(arrayValue.filter((v): v is string => typeof v === 'string' && v.startsWith('0x')).map(v => ethers.utils.arrayify(v)))
      );
    }
    // For other arrays, convert to strings and then to bytes
    return ethers.utils.hexlify(
      ethers.utils.concat(arrayValue.map(v => ethers.utils.toUtf8Bytes(String(v))))
    );
  }

  // For numbers or string numbers that should be treated as numbers
  if (schema instanceof z.ZodNumber || 
      (schema instanceof z.ZodString && !isNaN(Number(value)))) {
    const num = typeof value === 'number' ? value : Number(value);
    const bn = ethers.BigNumber.from(num);
    return ethers.utils.defaultAbiCoder.encode(['uint256'], [bn]);
  }

  // For hex strings (addresses), convert to bytes
  if (typeof value === 'string' && value.startsWith('0x')) {
    return ethers.utils.hexlify(ethers.utils.arrayify(value));
  }

  // For all other values, convert to UTF8 bytes
  return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(String(value)));
}

/**
 * Handles setting policy parameters for a tool and delegatee.
 */
export const handleSetPolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<void> => {
  try {
    // Get the list of permitted tools.
    const tools = await handleGetTools(awAdmin, pkp);
    if (!tools || (!tools.toolsWithPolicies.length && !tools.toolsWithoutPolicies.length)) {
      logger.info('No tools are currently permitted.');
      return;
    }

    // We can only set parameters for tools that have policies
    if (!tools.toolsWithPolicies.length) {
      logger.info('No tools with policies found. Please set a policy for a tool first using the "Set Tool Policy" command.');
      return;
    }

    // Prompt the user to select a tool.
    const tool = await promptSelectToolForPolicy({
      toolsWithPolicies: tools.toolsWithPolicies,
      toolsWithoutPolicies: [] // Only show tools with policies
    });

    // Get the list of delegatees.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // If no delegatees are found, log and return.
    if (!delegatees.length) {
      logger.info('No delegatees found for this PKP.');
      return;
    }

    // Prompt the user to select a delegatee.
    const delegatee = await promptSelectDelegateeFromList(delegatees, 'Select a delegatee to set policy parameters for:');

    // Check if a policy exists for this tool and delegatee
    const policy = await awAdmin.getToolPolicyForDelegatee(pkp.info.tokenId, tool.ipfsCid, delegatee);
    if (!policy.policyIpfsCid) {
      logger.info('No policy found for this tool and delegatee. Please set a policy first using the "Set Tool Policy" command.');
      return;
    }

    // Get the schema object shape from the tool's policy.
    const schema = tool.policy.schema;
    if (!(schema instanceof z.ZodObject)) {
      throw new Error('Tool policy schema is not a ZodObject');
    }
    const policyFields = Object.entries(schema.shape);
    const parameters: Record<string, unknown> = {};

    // Iterate over each policy field and prompt the user for input.
    for (const [field, fieldSchema] of policyFields) {
      // Skip the 'type' field as it is fixed.
      if (field === 'type') {
        parameters[field] = tool.name;
        continue;
      }

      // Skip the 'version' field as it is fixed.
      if (field === 'version') {
        parameters[field] = '1.0.0';
        continue;
      }

      // Handle array fields using the `promptArrayValues` function.
      if (fieldSchema instanceof z.ZodArray) {
        parameters[field] = await promptArrayValues(field, fieldSchema.element);
        continue;
      }

      // Prompt the user for non-array fields.
      const { value } = await prompts({
        type: 'text',
        name: 'value',
        message: `Enter value for ${field}:`,
        validate: (input) => {
          try {
            // Validate the input using the field's schema.
            (fieldSchema as z.ZodType).parse(input);
            return true;
          } catch (error) {
            if (error instanceof z.ZodError) {
              return `Invalid input: ${error.errors[0]?.message}`;
            }
            return 'Invalid input';
          }
        },
      });

      // If the user cancels the input, throw an error.
      if (!value) {
        throw new AwCliError(
          AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
          'Tool policy parameter setting cancelled.'
        );
      }

      // Add the validated value to the parameters object.
      parameters[field] = value;
    }

    // Validate the entire parameters object using the tool's schema.
    const validatedParameters = schema.parse(parameters);

    // Display the parameters and ask for confirmation.
    logger.info('Policy Parameters:');
    Object.entries(validatedParameters).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        logger.log(`${key}:`);
        if (value.length === 0) {
          logger.log('  (empty array)');
        } else {
          value.forEach((item) => logger.log(`  - ${item}`));
        }
      } else {
        logger.log(`${key}: ${value}`);
      }
    });

    const { confirmed } = await prompts({
      type: 'confirm',
      name: 'confirmed',
      message: 'Would you like to proceed with these parameters?',
      initial: true,
    });

    if (!confirmed) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
        'Tool policy parameter setting cancelled.'
      );
    }

    // Convert parameter values appropriately
    const parameterNames = Object.keys(validatedParameters);
    const convertedValues = parameterNames.map(name => 
      convertValueToBytes(name, validatedParameters[name], schema.shape[name])
    );

    // Log loading message.
    logger.loading('Setting policy parameters...');

    try {
      // Set the policy parameters.
      await awAdmin.setToolPolicyParametersForDelegatee(
        pkp.info.tokenId,
        tool.ipfsCid,
        delegatee,
        parameterNames,
        convertedValues
      );

      // Log success message.
      logger.success('Policy parameters set successfully.');
    } catch (error) {
      if (error instanceof Error) {
        logger.error(`Failed to set policy parameters: ${error.message}`);
      } else {
        logger.error('Failed to set policy parameters: Unknown error occurred');
      }
    }
  } catch (error) {
    // Handle specific errors related to policy parameter setting.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        logger.info('Policy parameter setting cancelled.');
        return;
      }
    }

    // For any other errors, log them in a user-friendly way
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    logger.log(`Failed to set policy parameters: ${errorMessage}`);
  }
}; 