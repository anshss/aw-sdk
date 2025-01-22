// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to enter policy parameter names.
 * This function allows the user to enter multiple parameter names until they indicate completion.
 *
 * @returns An array of parameter names.
 * @throws AwCliError - If the user cancels the operation.
 */
export const promptPolicyParameterNames = async (): Promise<string[]> => {
  const parameterNames: string[] = [];

  // Log instructions for the user.
  logger.info('Enter policy parameter names:');
  logger.log('(Press Enter without a value when done)\n');

  // Continuously prompt for parameter names until the user is done.
  while (true) {
    const { name } = await prompts({
      type: 'text',
      name: 'name',
      message: `Enter parameter name (${parameterNames.length + 1}):`,
    });

    // If no name is entered and we have at least one parameter, we're done.
    if (!name && parameterNames.length > 0) {
      break;
    }

    // If no name is entered and we have no parameters, confirm empty list.
    if (!name) {
      const { confirmed } = await prompts({
        type: 'confirm',
        name: 'confirmed',
        message: 'No parameters entered. Do you want to proceed with an empty list?',
        initial: false,
      });

      if (confirmed) break;
      continue;
    }

    // Add the parameter name to the list.
    parameterNames.push(name);
    logger.success(`Added: ${name}`);
  }

  return parameterNames;
};

/**
 * Prompts the user to enter policy parameter values.
 * This function collects values for each parameter name provided.
 *
 * @param parameterNames - The names of the parameters to collect values for.
 * @returns An array of parameter values.
 * @throws AwCliError - If the user cancels the operation.
 */
export const promptPolicyParameterValues = async (
  parameterNames: string[]
): Promise<any[]> => {
  const parameterValues: any[] = [];

  // Log instructions for the user.
  logger.info('Enter policy parameter values:');

  // Prompt for a value for each parameter name.
  for (const name of parameterNames) {
    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: `Enter value for ${name}:`,
    });

    // If no value is entered, throw an error.
    if (value === undefined) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
        'Policy parameter value entry cancelled.'
      );
    }

    // Add the value to the list.
    parameterValues.push(value);
  }

  return parameterValues;
}; 