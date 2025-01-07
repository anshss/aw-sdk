import { getToolByIpfsCid } from '@lit-protocol/fss-tool-registry';
import prompts from 'prompts';
import { z } from 'zod';

import { FssCliError, FssCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

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
        if (!input) return true; // Allow empty for completion
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

export const promptPolicyDetails = async (ipfsCid: string) => {
  const tool = getToolByIpfsCid(ipfsCid);
  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_SET_TOOL_POLICY_TOOL_NOT_IN_REGISTRY,
      `Tool not found for IPFS CID: ${ipfsCid}`
    );
  }

  logger.info('Tool Policy Configuration:');
  logger.log(`Name: ${tool.name}`);
  logger.log(`Description: ${tool.description}`);
  logger.log('');

  // Get the schema object shape
  const schema = tool.policy.schema as z.ZodObject<any>;
  const policyFields = Object.entries(schema.shape);
  const policyValues: Record<string, any> = {};

  for (const [field, fieldSchema] of policyFields) {
    // Skip type field as it's fixed
    if (field === 'type') {
      policyValues[field] = tool.name;
      continue;
    }

    if (field === 'version') {
      policyValues[field] = '1.0.0';
      continue;
    }

    // Handle array types differently
    if (fieldSchema instanceof z.ZodArray) {
      policyValues[field] = await promptArrayValues(field, fieldSchema.element);
      continue;
    }

    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: `Enter value for ${field}:`,
      validate: (input) => {
        try {
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

    if (!value) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
        'Tool policy setting cancelled.'
      );
    }

    policyValues[field] = value;
  }

  // Validate and encode the policy
  const validatedPolicy = tool.policy.schema.parse(policyValues);

  // Show policy details and ask for confirmation
  logger.info('Policy Details:');
  Object.entries(validatedPolicy).forEach(([key, value]) => {
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
    message: 'Would you like to proceed with these policy details?',
    initial: true,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  const encodedPolicy = tool.policy.encode(validatedPolicy);

  return { policy: encodedPolicy, version: validatedPolicy.version };
};
