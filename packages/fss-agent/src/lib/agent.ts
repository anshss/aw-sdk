import { OpenAI } from 'openai';
import { getToolForIntent } from './get-tool-for-intent';
import { parseToolParametersFromIntent } from './parse-tool-parameters';
import { type LitNetwork } from '@lit-protocol/fss-tool-registry';

/**
 * Represents an agent that analyzes user intent and matches it to an appropriate action
 * using OpenAI's API and a specified tool registry.
 */
export class FssAgent {
  /** Instance of the OpenAI client. */
  private openai: OpenAI;
  /** The OpenAI model to be used for analysis. */
  private openAiModel: string;

  /**
   * Creates an instance of the FssAgent.
   * @param {string} openAiApiKey - The API key for OpenAI.
   * @param {string} [openAiModel='gpt-4o-mini'] - The OpenAI model to use (defaults to 'gpt-4o-mini').
   */
  constructor(openAiApiKey: string, openAiModel = 'gpt-4o-mini') {
    this.openai = new OpenAI({ apiKey: openAiApiKey });
    this.openAiModel = openAiModel;
  }

  /**
   * Analyzes the provided intent and matches it to an appropriate action using the OpenAI model
   * and the LitNetwork tool registry.
   * @param {string} intent - The user intent to analyze.
   * @param {LitNetwork} litNetwork - The LitNetwork tool registry to match the intent against.
   * @returns {Promise<{ analysis: any, matchedTool: any, params: { foundParams: object, missingParams: string[] } }>} - An object containing the analysis results, the matched tool, and the parsed parameters.
   */
  public async analyzeIntentAndMatchAction(
    intent: string,
    litNetwork: LitNetwork
  ) {
    // Get the analysis and matched tool for the given intent
    const { analysis, matchedTool } = await getToolForIntent(
      this.openai,
      this.openAiModel,
      intent,
      litNetwork
    );

    // Parse parameters for the matched tool (if any)
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
