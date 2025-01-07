import prompts from 'prompts';
import type { FssTool } from '@lit-protocol/fss-tool';
import { FssCliError, FssCliErrorType } from '../../errors';

/**
 * Prompts the user to input parameters required for executing a tool.
 * The function iterates through the tool's parameter descriptions and collects user input for each parameter.
 * If a `pkpEthAddress` is provided, it is automatically used for the `pkpEthAddress` parameter without prompting.
 * After collecting all parameters, the function validates them using the tool's validation logic.
 *
 * @template T - A generic type representing the structure of the tool's parameters.
 * @param tool - The `FssTool` object for which parameters are being collected.
 * @param pkpEthAddress - Optional. The Ethereum address of the PKP (Programmable Key Pair) to be used as the `pkpEthAddress` parameter.
 * @returns A promise that resolves to an object containing the collected and validated parameters.
 * @throws {FssCliError} If the user cancels input for any parameter, an error of type `DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED` is thrown.
 * @throws {FssCliError} If the collected parameters fail validation, an error of type `DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID` is thrown, including details of the validation errors.
 */
export const promptToolParams = async <T extends Record<string, any>>(
  tool: FssTool<T, any>,
  pkpEthAddress?: string
) => {
  const params: Record<string, any> = {};

  // Iterate through each parameter description and prompt the user for input.
  for (const [paramName, description] of Object.entries(
    tool.parameters.descriptions
  )) {
    // If the parameter is 'pkpEthAddress' and a value is provided, skip prompting.
    if (paramName === 'pkpEthAddress' && pkpEthAddress !== undefined) {
      params.pkpEthAddress = pkpEthAddress;
      continue;
    }

    // Prompt the user for the parameter value.
    const { value } = await prompts({
      type: 'text', // Use a text input type for the parameter.
      name: 'value', // The name of the input.
      message: `Enter ${paramName} (${description}):`, // The message displayed to the user.
    });

    // If the user cancels the input, throw an error.
    if (value === undefined) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED,
        'Parameter input cancelled'
      );
    }

    // Store the collected parameter value.
    params[paramName] = value;
  }

  // Validate the collected parameters using the tool's validation logic.
  const validationResult = tool.parameters.validate(params);
  if (validationResult !== true) {
    // If validation fails, format the errors and throw an error.
    const errors = validationResult
      .map(({ param, error }) => `${param}: ${error}`)
      .join('\n');
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID,
      `Invalid parameters:\n${errors}`
    );
  }

  // Return the validated parameters.
  return params as T;
};
