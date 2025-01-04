import { OpenAI } from 'openai';

import { getToolForIntent } from './get-tool-for-intent';
import { parseToolParametersFromIntent } from './parse-tool-parameters';

export class FssAgent {
  private openai: OpenAI;
  private openAiModel: string;

  constructor(openAiApiKey: string, openAiModel = 'gpt-4o-mini') {
    this.openai = new OpenAI({ apiKey: openAiApiKey });
    this.openAiModel = openAiModel;
  }

  public async analyzeIntentAndMatchAction(intent: string) {
    const { analysis, matchedTool } = await getToolForIntent(
      this.openai,
      this.openAiModel,
      intent
    );

    const params = matchedTool
      ? await parseToolParametersFromIntent(
          this.openai,
          this.openAiModel,
          intent,
          matchedTool
        )
      : { foundParams: {}, missingParams: [] };

    return { analysis, matchedTool, params };
  }
}
