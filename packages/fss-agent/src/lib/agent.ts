// Import the OpenAI class from the 'openai' package.
import { OpenAI } from 'openai';

// Import helper functions for matching tools and parsing parameters based on intent.
import { getToolForIntent } from './get-tool-for-intent';
import { parseToolParametersFromIntent } from './parse-tool-parameters';
import { type LitNetwork } from '@lit-protocol/fss-tool-registry';

/**
 * FssAgent class is responsible for analyzing user intents and matching them to appropriate tools and parameters.
 * It uses OpenAI's API to perform intent analysis and parameter extraction.
 */
export class FssAgent {
  // Private instance of the OpenAI client.
  private openai: OpenAI;

  // The OpenAI model to be used for analysis (default is 'gpt-4o-mini').
  private openAiModel: string;

  /**
   * Constructor for the FssAgent class.
   * @param openAiApiKey - The API key for OpenAI.
   * @param openAiModel - The name of the OpenAI model to use (default is 'gpt-4o-mini').
   */
  constructor(openAiApiKey: string, openAiModel = 'gpt-4o-mini') {
    // Initialize the OpenAI client with the provided API key.
    this.openai = new OpenAI({ apiKey: openAiApiKey });

    // Set the OpenAI model to be used.
    this.openAiModel = openAiModel;
  }

  /**
   * Analyzes the provided intent and matches it to an appropriate tool and parameters.
   * @param intent - The user intent to analyze.
   * @param litNetwork - The Lit network to use for the analysis.
   * @returns An object containing:
   *   - analysis: The analysis of the intent.
   *   - matchedTool: The tool matched to the intent (if any).
   *   - params: The parameters extracted from the intent for the matched tool.
   */
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

    // If a tool is matched, parse the parameters from the intent using `parseToolParametersFromIntent`.
    const params = matchedTool
      ? await parseToolParametersFromIntent(
          this.openai,
          this.openAiModel,
          intent,
          matchedTool
        )
      : { foundParams: {}, missingParams: [] }; // If no tool is matched, return empty parameters.

    // Return the analysis, matched tool, and parameters.
    return { analysis, matchedTool, params };
  }
}
