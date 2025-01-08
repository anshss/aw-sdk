import { OpenAI } from 'openai';
import type { FssTool } from '@lit-protocol/fss-tool';

import { getToolMatchingPrompt } from './get-tool-matching-prompt';

export async function getToolForIntent(
  openai: OpenAI,
  openAiModel: string,
  userIntent: string,
  registeredTools: FssTool<any, any>[]
): Promise<{
  analysis: any;
  matchedTool: FssTool | null;
}> {
  const completion = await openai.chat.completions.create({
    model: openAiModel,
    messages: [
      {
        role: 'system',
        content: getToolMatchingPrompt(registeredTools),
      },
      {
        role: 'user',
        content: userIntent,
      },
    ],
    response_format: { type: 'json_object' },
  });

  const analysis = JSON.parse(completion.choices[0].message.content || '{}');
  const matchedTool = analysis.recommendedCID
    ? registeredTools.find(
        (tool) => tool.ipfsCid === analysis.recommendedCID
      ) || null
    : null;

  return { analysis, matchedTool };
}
