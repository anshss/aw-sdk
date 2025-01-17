// Import the OpenAI class from the 'openai' package.
import { OpenAI } from 'openai';

// Import the AwTool type from the '@lit-protocol/aw-tool' package.
import type { AwTool } from '@lit-protocol/aw-tool';

/**
 * Parses and validates parameters from a user's intent for a given tool.
 * This function uses OpenAI's API to extract parameter values and ensures they conform to the tool's validation rules.
 *
 * @template TParams - A generic type representing the tool's parameter structure.
 * @template TPolicy - A generic type representing the tool's policy structure.
 * @param openai - An instance of the OpenAI client.
 * @param openAiModel - The name of the OpenAI model to use for parsing.
 * @param intent - The user's intent as a string.
 * @param tool - The tool for which parameters are being parsed.
 * @returns A Promise that resolves to an object containing:
 *   - foundParams: A partial object of the parsed parameters.
 *   - missingParams: An array of parameter names that could not be parsed.
 *   - validationErrors: An array of validation errors for invalid parameters.
 */
export async function parseToolParametersFromIntent<
  TParams extends Record<string, any>,
  TPolicy extends { type: string }
>(
  openai: OpenAI,
  openAiModel: string,
  intent: string,
  tool: AwTool<TParams, TPolicy>
): Promise<{
  foundParams: Partial<TParams>;
  missingParams: Array<keyof TParams>;
  validationErrors: Array<{ param: string; error: string }>;
}> {
  // Use OpenAI's API to parse parameters from the user's intent.
  const completion = await openai.chat.completions.create({
    model: openAiModel,
    messages: [
      {
        role: 'system',
        content: `You are a parameter parser for web3 transactions. Given a user's intent and a tool's required parameters, extract the parameter values from the intent.
        
        Tool: ${tool.name}
        Description: ${tool.description}
        Parameters:
        ${Object.entries(tool.parameters.descriptions)
          .map(([param, description]) => {
            // Try parsing an empty string to get validation error messages
            const result = tool.parameters.schema.safeParse({ [param]: '' });
            const validationRules = !result.success
              ? result.error.issues
                  .filter((issue) => issue.path[0] === param)
                  .map((issue) => issue.message)
                  .join(', ')
              : '';

            return `- ${param}: ${description}${
              validationRules ? `\n  Validation: ${validationRules}` : ''
            }`;
          })
          .join('\n')}

        Return a JSON object with:
        {
          "foundParams": {
            "paramName": "extractedValue",
            ...
          },
          "missingParams": ["paramName1", "paramName2", ...]
        }

        Important:
        1. Only include parameters in foundParams if you are completely certain about their values
        2. For any parameters you're unsure about or can't find in the intent, include them in missingParams
        3. All parameter values must be strings
        4. For token amounts, return them as decimal strings (e.g., "1.5", "10.0")
        5. For addresses, ensure they start with "0x" and are the correct length`,
      },
      {
        role: 'user',
        content: intent,
      },
    ],
    response_format: { type: 'json_object' },
  });

  // Parse the result from OpenAI's response.
  const result = JSON.parse(completion.choices[0].message.content || '{}');

  // Validate the found parameters using the tool's validation function.
  const foundParams = result.foundParams || {};
  const validationResult = tool.parameters.validate(foundParams);

  // If validation passes, return the found and missing parameters.
  if (validationResult === true) {
    return {
      foundParams,
      missingParams:
        result.missingParams || Object.keys(tool.parameters.descriptions),
      validationErrors: [],
    };
  }

  // If validation fails, filter out invalid parameters and add them to missingParams.
  const invalidParams = new Set(validationResult.map((error) => error.param));
  const filteredParams: Partial<TParams> = {};
  const missingParams = new Set<keyof TParams>(result.missingParams || []);

  // Keep only valid parameters in foundParams.
  Object.entries(foundParams).forEach(([param, value]) => {
    if (!invalidParams.has(param)) {
      filteredParams[param as keyof TParams] = value as TParams[keyof TParams];
    } else {
      missingParams.add(param as keyof TParams);
    }
  });

  // Return the filtered parameters, missing parameters, and validation errors.
  return {
    foundParams: filteredParams,
    missingParams: Array.from(missingParams),
    validationErrors: validationResult,
  };
}
