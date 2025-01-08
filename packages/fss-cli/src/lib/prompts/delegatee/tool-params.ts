import prompts from 'prompts';
import type { FssTool } from '@lit-protocol/fss-tool';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptToolParams = async <T extends Record<string, any>>(
  tool: FssTool<T, any>,
  pkpEthAddress?: string,
  options?: {
    missingParams?: Array<keyof T>;
    foundParams?: Partial<T>;
  }
) => {
  const params: Record<string, any> = { ...options?.foundParams };
  const paramsToPrompt = options?.missingParams
    ? Object.entries(tool.parameters.descriptions).filter(([paramName]) =>
        options.missingParams?.includes(paramName as keyof T)
      )
    : Object.entries(tool.parameters.descriptions);

  // Get each parameter from the user
  for (const [paramName, description] of paramsToPrompt) {
    if (paramName === 'pkpEthAddress' && pkpEthAddress !== undefined) {
      params.pkpEthAddress = pkpEthAddress;
      continue;
    }

    const { value } = await prompts({
      type: 'text',
      name: 'value',
      message: `Enter ${paramName} (${description}):`,
    });

    if (value === undefined) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED,
        'Parameter input cancelled'
      );
    }

    params[paramName] = value;
  }

  // Validate all parameters
  const validationResult = tool.parameters.validate(params);
  if (validationResult !== true) {
    const errors = validationResult
      .map(({ param, error }) => `${param}: ${error}`)
      .join('\n');
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID,
      `Invalid parameters:\n${errors}`
    );
  }

  return params as T;
};
