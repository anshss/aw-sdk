import { OpenAI } from 'openai';

import { getToolForIntent } from './get-tool-for-intent';
import { parseToolParametersFromIntent } from './parse-tool-parameters';
import { type LitNetwork } from '@lit-protocol/fss-tool-registry';

export class FssAgent {
  private openai: OpenAI;
  private openAiModel: string;

  constructor(openAiApiKey: string, openAiModel = 'gpt-4o-mini') {
    this.openai = new OpenAI({ apiKey: openAiApiKey });
    this.openAiModel = openAiModel;
  }

  public async analyzeIntentAndMatchAction(
    intent: string,
    litNetwork: LitNetwork
  ) {
    const { analysis, matchedTool } = await getToolForIntent(
      this.openai,
      this.openAiModel,
      intent,
      litNetwork
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
