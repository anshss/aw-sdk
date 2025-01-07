# @lit-protocol/fss-tool-signing-simple

A Lit AI Agent tool for basic message signing. This package provides a simple way to sign messages with policy-based controls.

## Features

- Message signing
- Policy-based signing limits
- Message prefix validation
- Automatic signature generation
- Detailed logging
- Error handling with descriptive messages

## Installation

```bash
pnpm add @lit-protocol/fss-tool-signing-simple
```

## Usage

### Basic Message Signing

```typescript
import { LitAgent } from '@lit-protocol/fss';

const agent = new LitAgent(authKey, openAiKey);
await agent.init();

// Execute message signing
const result = await agent.executeTool(
  'ipfs://Qm...', // Simple Signing tool CID
  {
    message: 'Hello World' // Message to sign
  }
);
```

### Policy Configuration

The tool supports flexible policy configuration to ensure secure signing:

```typescript
const policy = {
  type: 'SigningSimple',
  version: '1.0.0',
  // List of allowed message prefixes
  allowedPrefixes: [
    'Hello',
    'Verify:'
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

1. Check delegatee authorization
2. Validate message against policy (must start with an allowed prefix)
3. Generate ECDSA signature
4. Return signed message and signature

### Required Parameters

| Parameter  | Type     | Description                                                |
| ---------- | -------- | ---------------------------------------------------------- |
| `message`  | `string` | Message to sign                                           |

### Policy Parameters

| Parameter        | Type       | Description                                    |
| --------------- | ---------- | ---------------------------------------------- |
| `type`          | `string`   | Must be 'SigningSimple'                        |
| `version`       | `string`   | Policy version (e.g., '1.0.0')                 |
| `allowedPrefixes`| `string[]`| Array of allowed message prefixes              |

## Deployment

1. Set up your environment:
   - Copy `.env.template` to `.env`
   - Add your `PINATA_JWT` to the `.env` file

2. Deploy your Lit Action to IPFS:
```bash
pnpm nx deploy fss-tool-signing-simple
```

This will pin your Lit Action code to IPFS using Pinata.

## Development

### Building

```bash
pnpm nx build fss-tool-signing-simple
```

### Testing

```bash
pnpm nx test fss-tool-signing-simple
```

## Contributing

Please see our [Contributing Guide](../../CONTRIBUTING.md) for details on how to contribute to this package.

## License

MIT
