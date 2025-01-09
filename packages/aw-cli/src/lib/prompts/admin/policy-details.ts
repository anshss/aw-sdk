// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the zod library for schema validation.
import { z } from 'zod';

// Import the AwTool type from the '@lit-protocol/agent-wallet' package.
import { type AwTool } from '@lit-protocol/agent-wallet';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to enter values for an array field in a policy.
 * This function handles validation of each value using a Zod schema and allows the user to
 * enter multiple values until they indicate completion by pressing Enter without a value.
 *
 * @param fieldName - The name of the array field.
 * @param schema - The Zod schema for validating individual array elements.
 * @returns An array of validated values.
 */
const promptArrayValues = async (
  fieldName: string,
  schema: z.ZodType
): Promise<string[]> => {
  // Initialize an array to store the entered values.
  const values: string[] = [];

  // Log instructions for the user.
  logger.info(`Entering values for ${fieldName}:`);
  logger.log('(Press Enter without a value when done)\n');

  // Continuously prompt the user to enter values.
  while (true) {
    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: `Enter value for ${fieldName} (${values.length + 1}):`,
      validate: (input) => {
        // Allow empty input to indicate completion.
        if (!input) return true;

        // Validate the input using the provided Zod schema.
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

    // If the user presses Enter without entering a value, check if the array is empty.
    if (!value) {
      if (values.length === 0) {
        // Prompt the user to confirm leaving the array empty.
        const { confirmed } = await prompts({
          type: 'confirm',
          name: 'confirmed',
          message: 'No values entered. Do you want to leave this array empty?',
          initial: false,
        });

        // If the user confirms, exit the loop.
        if (confirmed) break;

        // Otherwise, continue prompting for values.
        continue;
      }

      // Exit the loop if the user is done entering values.
      break;
    }

    // Add the validated value to the array and log success.
    values.push(value);
    logger.success(`Added: ${value}`);
  }

  // Return the array of validated values.
  return values;
};

/**
 * Prompts the user to configure policy details for a tool.
 * This function handles input for all policy fields, validates the input using the tool's schema,
 * and encodes the policy. It also confirms the policy details with the user before proceeding.
 *
 * @param tool - The tool for which to configure the policy.
 * @returns An object containing the encoded policy and version.
 * @throws AwCliError - If the user cancels the operation or provides invalid input.
 */
export const promptPolicyDetails = async (tool: AwTool<any, any>) => {
  // Log the tool details for context.
  logger.info('Tool Policy Configuration:');
  logger.log(`Name: ${tool.name}`);
  logger.log(`Description: ${tool.description}`);
  logger.log('');

  // Get the schema object shape from the tool's policy.
  const schema = tool.policy.schema as z.ZodObject<any>;
  const policyFields = Object.entries(schema.shape);
  const policyValues: Record<string, any> = {};

  // Iterate over each policy field and prompt the user for input.
  for (const [field, fieldSchema] of policyFields) {
    // Skip the 'type' field as it is fixed.
    if (field === 'type') {
      policyValues[field] = tool.name;
      continue;
    }

    // Skip the 'version' field as it is fixed.
    if (field === 'version') {
      policyValues[field] = '1.0.0';
      continue;
    }

    // Handle array fields using the `promptArrayValues` function.
    if (fieldSchema instanceof z.ZodArray) {
      policyValues[field] = await promptArrayValues(field, fieldSchema.element);
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
        'Tool policy setting cancelled.'
      );
    }

    // Add the validated value to the policy object.
    policyValues[field] = value;
  }

  // Validate the entire policy object using the tool's schema.
  const validatedPolicy = tool.policy.schema.parse(policyValues);

  // Display the policy details and ask for confirmation.
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

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  // Encode the validated policy.
  const encodedPolicy = tool.policy.encode(validatedPolicy);

  // Return the encoded policy and version.
  return { policy: encodedPolicy, version: validatedPolicy.version };
};
