import { OpenAI } from 'openai';
import type { FssTool } from '@lit-protocol/fss-tool';

export async function parseToolParametersFromIntent<
  TParams extends Record<string, any>,
  TPolicy extends { type: string }
>(
  openai: OpenAI,
  openAiModel: string,
  intent: string,
  tool: FssTool<TParams, TPolicy>
): Promise<{
  foundParams: Partial<TParams>;
  missingParams: Array<keyof TParams>;
  validationErrors: Array<{ param: string; error: string }>;
}> {
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

  const result = JSON.parse(completion.choices[0].message.content || '{}');

  // Validate found parameters
  const foundParams = result.foundParams || {};
  const validationResult = tool.parameters.validate(foundParams);

  if (validationResult === true) {
    return {
      foundParams,
      missingParams:
        result.missingParams || Object.keys(tool.parameters.descriptions),
      validationErrors: [],
    };
  }

  // If validation fails, only treat invalid params as missing
  const invalidParams = new Set(validationResult.map((error) => error.param));
  const filteredParams: Partial<TParams> = {};
  const missingParams = new Set<keyof TParams>(result.missingParams || []);

  // Keep only valid params in foundParams
  Object.entries(foundParams).forEach(([param, value]) => {
    if (!invalidParams.has(param)) {
      filteredParams[param as keyof TParams] = value as TParams[keyof TParams];
    } else {
      missingParams.add(param as keyof TParams);
    }
  });

  return {
    foundParams: filteredParams,
    missingParams: Array.from(missingParams),
    validationErrors: validationResult,
  };
}
