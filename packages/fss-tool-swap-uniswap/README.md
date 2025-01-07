# @lit-protocol/fss-tool-swap-uniswap

A Lit AI Agent tool for performing Uniswap V3 token swaps. This package provides a secure way to swap tokens using Uniswap V3.

## Features

- Token swaps using Uniswap V3
- Policy-based swap limits
- Token allowlist support
- Best quote calculation across fee tiers (0.05% and 0.3%)
- Automatic gas estimation and optimization
- Detailed transaction logging
- Error handling with descriptive messages

## Installation

```bash
pnpm add @lit-protocol/fss-tool-swap-uniswap
```

## Supported Networks

The tool supports the following networks with hardcoded Uniswap V3 contracts:

- Ethereum Mainnet (Chain ID: 1)
  - Router: `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45`
  - Quoter: `0x61fFE014bA17989E743c5F6cB21bF9697530B21e`
- Base (Chain ID: 8453)
  - Router: `0x2626664c2603336E57B271c5C0b26F421741e481`
  - Quoter: `0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a`
- Arbitrum (Chain ID: 42161)
  - Router: `0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45`
  - Quoter: `0x61fFE014bA17989E743c5F6cB21bF9697530B21e`

## Usage

### Basic Token Swap

```typescript
import { LitAgent } from '@lit-protocol/fss';

const agent = new LitAgent(authKey, openAiKey);
await agent.init();

// Execute token swap
const result = await agent.executeTool(
  'ipfs://Qm...', // Uniswap Swap tool CID
  {
    tokenIn: '0x1234...', // Input token contract address (must be valid Ethereum address)
    tokenOut: '0x5678...', // Output token contract address (must be valid Ethereum address)
    amountIn: '1.5', // Amount of input token as decimal string
    chainId: '1', // Chain ID as string (1 for Ethereum, 8453 for Base, 42161 for Arbitrum)
    rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/your-api-key' // Must be HTTPS URL
  }
);
```

### Policy Configuration

The tool supports flexible policy configuration to ensure secure token swaps:

```typescript
const policy = {
  type: 'SwapUniswap',
  version: '1.0.0',
  // Maximum amount in base units (e.g., wei)
  maxAmount: '1000000000000000000',
  // List of allowed token addresses
  allowedTokens: [
    '0x4070c8325e278ca1056e602e08d16d2D5cd79b27',
    '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
  ]
};

// Apply policy through agent
const result = await agent.executeTool(
  'ipfs://Qm...',
  params,
  {
    policyCallback: async () => ({
      usePolicy: true,
      policyValues: policy
    })
  }
);
```

## Tool Implementation Details

The tool is implemented as a Lit Action that follows this execution flow:

1. Validate network and set Uniswap contract addresses
2. Check delegatee authorization
3. Validate inputs against policy (maxAmount and allowedTokens)
4. Get token info (decimals and balances)
5. Get best quote across fee tiers (3000 = 0.3% and 500 = 0.05%)
6. Approve tokens and execute swap

### Required Parameters

| Parameter  | Type     | Description                                                |
| ---------- | -------- | ---------------------------------------------------------- |
| `tokenIn`  | `string` | Input token contract address (must be valid Ethereum address) |
| `tokenOut` | `string` | Output token contract address (must be valid Ethereum address) |
| `amountIn` | `string` | Amount of input token as decimal string (e.g., "1.5")      |
| `chainId`  | `string` | Chain ID as string ("1", "8453", or "42161")              |
| `rpcUrl`   | `string` | HTTPS RPC endpoint URL for the blockchain network          |

### Policy Parameters

| Parameter       | Type       | Description                                    |
| -------------- | ---------- | ---------------------------------------------- |
| `type`         | `string`   | Must be 'SwapUniswap'                         |
| `version`      | `string`   | Policy version (e.g., '1.0.0')                |
| `maxAmount`    | `string`   | Maximum swap amount in base units              |
| `allowedTokens`| `string[]` | Array of allowed token contract addresses      |

## Deployment

1. Set up your environment:
   - Copy `.env.template` to `.env`
   - Add your `PINATA_JWT` to the `.env` file

2. Deploy your Lit Action to IPFS:
```bash
pnpm nx deploy fss-tool-swap-uniswap
```

This will pin your Lit Action code to IPFS using Pinata.

## Development

### Building

```bash
pnpm nx build fss-tool-swap-uniswap
```

### Testing

```bash
pnpm nx test fss-tool-swap-uniswap
```

## Contributing

Please see our [Contributing Guide](../../CONTRIBUTING.md) for details on how to contribute to this package.

## License

MIT
