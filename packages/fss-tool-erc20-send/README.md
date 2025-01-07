# @lit-protocol/fss-tool-erc20-send

A Lit AI Agent tool for sending ERC20 tokens. This package provides a secure way to transfer ERC20 tokens with policy-based controls.

## Features

- ERC20 token transfers
- Policy-based transfer limits
- Token and recipient allowlist support
- Automatic gas estimation and optimization
- Detailed transaction logging
- Error handling with descriptive messages

## Installation

```bash
pnpm add @lit-protocol/fss-tool-erc20-send
```

## Usage

### Basic Token Transfer

```typescript
import { LitAgent } from '@lit-protocol/fss';

const agent = new LitAgent(authKey, openAiKey);
await agent.init();

// Execute token transfer
const result = await agent.executeTool(
  'ipfs://Qm...', // ERC20 Send tool CID
  {
    tokenIn: '0x1234...', // Token contract address (must be valid Ethereum address)
    recipientAddress: '0x5678...', // Recipient address (must be valid Ethereum address)
    amountIn: '1.5', // Amount of tokens as decimal string
    chainId: '1', // Chain ID as string
    rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/your-api-key' // Must be HTTPS URL
  }
);
```

### Policy Configuration

The tool supports flexible policy configuration to ensure secure token transfers:

```typescript
const policy = {
  type: 'SendERC20',
  version: '1.0.0',
  // Maximum amount in base units (e.g., wei)
  maxAmount: '1000000000000000000',
  // List of allowed token addresses
  allowedTokens: [
    '0x4070c8325e278ca1056e602e08d16d2D5cd79b27',
    '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
  ],
  // List of allowed recipient addresses
  allowedRecipients: [
    '0x600DC16993EA1AbdA674A20d432F93041cDa2ef4',
    '0x...'
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

1. Parameter validation and normalization
2. Policy constraint verification
3. Token info gathering (decimals and balance checks)
4. Gas estimation and optimization
5. Transaction construction and signing
6. Broadcasting and confirmation

### Required Parameters

| Parameter          | Type     | Description                                                |
| ----------------- | -------- | ---------------------------------------------------------- |
| `tokenIn`         | `string` | Token contract address (must be valid Ethereum address)    |
| `recipientAddress`| `string` | Recipient address (must be valid Ethereum address)         |
| `amountIn`        | `string` | Amount of tokens as decimal string (e.g., "1.5")          |
| `chainId`         | `string` | Chain ID as string                                        |
| `rpcUrl`          | `string` | HTTPS RPC endpoint URL for the blockchain network         |

### Policy Parameters

| Parameter          | Type       | Description                                    |
| ----------------- | ---------- | ---------------------------------------------- |
| `type`            | `string`   | Must be 'SendERC20'                           |
| `version`         | `string`   | Policy version (e.g., '1.0.0')                |
| `maxAmount`       | `string`   | Maximum transfer amount in base units          |
| `allowedTokens`   | `string[]` | Array of allowed token contract addresses      |
| `allowedRecipients`| `string[]`| Array of allowed recipient addresses          |

## Deployment

1. Set up your environment:
   - Copy `.env.template` to `.env`
   - Add your `PINATA_JWT` to the `.env` file

2. Deploy your Lit Action to IPFS:
```bash
pnpm nx deploy fss-tool-erc20-send
```

This will pin your Lit Action code to IPFS using Pinata.

## Development

### Building

```bash
pnpm nx build fss-tool-erc20-send
```

### Testing

```bash
pnpm nx test fss-tool-erc20-send
```

## Contributing

Please see our [Contributing Guide](../../CONTRIBUTING.md) for details on how to contribute to this package.

## License

MIT
