// Import the OpenAI class from the 'openai' package.
import { OpenAI } from 'openai';
import type {
  IntentMatcher,
  IntentMatcherResponse,
} from '@lit-protocol/aw-signer';
import type { FssTool } from '@lit-protocol/fss-tool';

// Import helper functions for matching tools and parsing parameters based on intent.
import { getToolForIntent } from './get-tool-for-intent';
import { parseToolParametersFromIntent } from './parse-tool-parameters';

export class OpenAiIntentMatcher implements IntentMatcher {
  public static readonly name = 'OpenAI Intent Matcher';
  public static readonly requiredCredentialNames = ['openAiApiKey'] as const;

  private openai: OpenAI;
  private model: string;

  constructor(apiKey: string, model = 'gpt-4o-mini') {
    this.openai = new OpenAI({ apiKey: apiKey });
    this.model = model;
  }

  public async analyzeIntentAndMatchTool(
    intent: string,
    registeredTools: FssTool<any, any>[]
  ): Promise<IntentMatcherResponse<any>> {
    if (!this.openai) {
      throw new Error(
        'OpenAI client not initialized. Please set credentials first.'
      );
    }

    const { analysis, matchedTool } = await getToolForIntent(
      this.openai,
      this.model,
      intent,
      registeredTools
    );

    // If a tool is matched, parse the parameters from the intent using `parseToolParametersFromIntent`.
    const params = matchedTool
      ? await parseToolParametersFromIntent(
          this.openai,
          this.model,
          intent,
          matchedTool
        )
      : { foundParams: {}, missingParams: [] }; // If no tool is matched, return empty parameters.

    // Return the analysis, matched tool, and parameters.
    return { analysis, matchedTool, params };
  }
}
