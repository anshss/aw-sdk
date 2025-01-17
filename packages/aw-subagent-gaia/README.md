# Subagent: Intent Parsing and Tool Matching Using Gaia

Subagent is a utility that uses Gaia's open-source LLM APIs to parse user intents and match them to the appropriate tools. It's designed to provide similar functionality as OpenAI-based solutions but with the benefits of using open-source, customizable LLMs through the Gaia network.

## How It Works

- **Intent Matching**: Subagent analyzes a user's intent (e.g., "I want to mint an NFT") and matches it to a registered tool.
- **Parameter Parsing**: If a tool is matched, Subagent extracts and validates the required parameters from the user's intent.
- **Gaia Integration**: It uses Gaia's LLM API to perform intent analysis and parameter extraction, providing a cost-effective and customizable alternative to proprietary solutions.

## Example Usage

```typescript
import { OpenAiIntentMatcher } from './agent';
import type { AwTool } from '@lit-protocol/aw-tool';

// Initialize Subagent with Gaia node
const baseUrl = 'https://YOUR-NODE-ID.gaia.domains/v1';
const apiKey = 'your-gaia-api-key';
const model = 'llama'; // or other supported models
const intentMatcher = new OpenAiIntentMatcher(baseUrl, apiKey, model);

// Register tools
const registeredTools: AwTool<any, any>[] = [
  {
    name: 'MintNFT',
    description: 'Mint a new NFT',
    ipfsCid: 'QmExampleCID1',
    parameters: {
      descriptions: {
        tokenId: 'The ID of the token to mint',
        recipient: 'The address of the recipient',
      },
      schema: {}, // Zod schema for validation
      validate: (params) => true, // Validation logic
    },
  },
  // Add more tools as needed
];

// Analyze user intent
const userIntent = "I want to mint an NFT with token ID 123 to address 0x123...";
const result = await intentMatcher.analyzeIntentAndMatchTool(userIntent, registeredTools);

// Check results
if (result.matchedTool) {
  console.log('Matched Tool:', result.matchedTool.name);
  console.log('Found Parameters:', result.params.foundParams);
  console.log('Missing Parameters:', result.params.missingParams);
} else {
  console.log('No matching tool found.');
}
```

## Key Features

- **Intent Matching:** Matches user intents to registered tools using Gaia's LLMs.
- **Parameter Extraction:** Parses and validates parameters from the user's intent.
- **Gaia Integration:** Uses Gaia's network of open-source LLMs for accurate intent analysis.
- **Customizable Models:** Choose from various open-source LLMs available on the Gaia network.
- **Cost-Effective:** Leverage community-run nodes for lower operational costs.

## Constructor Options
```typescript
new OpenAiIntentMatcher(
  baseUrl?: string,  // Your Gaia node URL (defaults to https://llama8b.gaia.domains/v1)
  apiKey: string,    // Your Gaia API key
  model?: string     // Model name (defaults to 'llama')
)
```

## Benefits Over Traditional Solutions

- **Open Source:** Uses open-source LLMs through Gaia's network instead of proprietary models.
- **Customizable:** Choose from various models or run your own fine-tuned versions.
- **Cost Control:** Predictable costs through Gaia's token economy.
- **Community Driven:** Benefit from a network of community-maintained nodes.

Subagent makes it easy to parse user intents and match them to the right tools while leveraging the benefits of open-source LLMs through Gaia. It provides a sustainable and customizable alternative to proprietary AI solutions for web3 workflows.