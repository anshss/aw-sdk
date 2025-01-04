import { OpenAI } from 'openai';
import type { ToolInfo } from '@lit-protocol/fss-tool-registry';

export async function parseToolParametersFromIntent(
  openai: OpenAI,
  openAiModel: string,
  intent: string,
  tool: ToolInfo
): Promise<{
  foundParams: Record<string, string>;
  missingParams: string[];
}> {
  const completion = await openai.chat.completions.create({
    model: openAiModel,
    messages: [
      {
        role: 'system',
        content: `You are a parameter parser for web3 transactions. Given a user's intent and a tool's required parameters, extract the parameter values from the intent.
        
        Tool: ${tool.name}
        Parameters:
        ${tool.parameters
          .map((param) => `- ${param.name}: ${param.description}`)
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
  return {
    foundParams: result.foundParams || {},
    missingParams: result.missingParams || [],
  };
}
