# @lit-protocol/aw-signer

The signer package is responsible for PKP (Programmable Key Pair) management, signing operations, and policy enforcement in the Lit Protocol Agent Wallet system. It provides two main roles: Admin and Delegatee.

## Installation

```bash
pnpm add @lit-protocol/aw-signer
```

## Core Features

- **PKP Management**: Mint and manage PKPs
- **Policy Enforcement**: Define and enforce tool execution policies
- **Delegatee Management**: Add and remove delegatees
- **Tool Execution**: Execute tools within policy constraints
- **Network Support**: Support for multiple Lit networks (datil-dev, datil-test, datil)

## Execution Flow

![Execution Flow](../../docs/diagrams/aw-signer/diagram.png)

## Usage

### As an Admin

The Admin role is responsible for managing PKPs, delegatees, and policies:

```typescript
import { Admin } from '@lit-protocol/aw-signer';

// Initialize Admin with EOA private key
const admin = new Admin({
  type: 'eoa',
  privateKey: 'your-private-key',
  litNetwork: 'datil-dev'
});

// Mint a new PKP
const pkp = await admin.mintPkp();

// Add a delegatee
await admin.addDelegatee(pkp.tokenId, 'delegatee-address');

// Permit a tool
await admin.permitTool(pkp.tokenId, 'tool-ipfs-cid');

// Set tool policy
await admin.setToolPolicy(
  pkp.tokenId,
  'tool-ipfs-cid',
  policyData,
  'v1'
);

// Get registered tools
const tools = await admin.getRegisteredToolsForPkp(pkp.tokenId);
```

### As a Delegatee

The Delegatee role executes tools within the constraints set by the Admin:

```typescript
import { Delegatee } from '@lit-protocol/aw-signer';

// Initialize Delegatee with EOA private key
const delegatee = new Delegatee({
  type: 'eoa',
  privateKey: 'your-private-key',
  litNetwork: 'datil-dev'
});

// Get delegated PKPs
const pkps = await delegatee.getDelegatedPkps();

// Get available tools
const tools = await delegatee.getRegisteredToolsForPkp(pkpTokenId);

// Execute a tool
await delegatee.executeTool({
  pkpTokenId,
  ipfsCid,
  params: toolParams,
  authSig,
  jsParams
});
```

### Intent-Based Tool Selection

The Delegatee can also select tools based on natural language intents:

```typescript
// Get a tool based on intent
const { tool, params } = await delegatee.getToolViaIntent(
  pkpTokenId,
  'Transfer 1 ETH to 0x123...',
  intentMatcher
);

// Execute the selected tool
await delegatee.executeTool({
  pkpTokenId,
  ipfsCid: tool.ipfsCid,
  params,
  authSig,
  jsParams
});
```

## Configuration

### Admin Configuration

```typescript
interface AdminConfig {
  type: 'eoa';                  // Currently only EOA is supported
  privateKey?: string;          // Admin's private key
  litNetwork?: LitNetwork;      // 'datil-dev' | 'datil-test' | 'datil'
  debug?: boolean;              // Enable debug logging
}
```

### Delegatee Configuration

```typescript
interface DelegateeConfig {
  type: 'eoa';                  // Currently only EOA is supported
  privateKey?: string;          // Delegatee's private key
  litNetwork?: LitNetwork;      // 'datil-dev' | 'datil-test' | 'datil'
  debug?: boolean;              // Enable debug logging
}
```

## Tool Policies

Policies define constraints for tool execution:

```typescript
// Example ERC20 Transfer Policy
interface ERC20TransferPolicy {
  maxAmount: string;            // Maximum transfer amount
  allowedTokens: string[];      // Allowed token addresses
  allowedRecipients: string[];  // Allowed recipient addresses
}

// Setting a policy
await admin.setToolPolicy(
  pkpTokenId,
  toolIpfsCid,
  {
    maxAmount: '1000000000000000000', // 1 ETH
    allowedTokens: ['0x...'],
    allowedRecipients: ['0x...']
  },
  'v1'
);
```

## Error Handling

The package provides specific error types for better error handling:

```typescript
import { AwSignerError, AwSignerErrorType } from '@lit-protocol/aw-signer';

try {
  await admin.permitTool({ ipfsCid });
} catch (error) {
  if (error instanceof AwSignerError) {
    switch (error.type) {
      case AwSignerErrorType.ADMIN_PERMIT_TOOL_FAILED:
        console.error('Failed to permit tool:', error.message);
        break;
      case AwSignerErrorType.ADMIN_NOT_INITIALIZED:
        console.error('Admin not initialized:', error.message);
        break;
      case AwSignerErrorType.ADMIN_MISSING_PRIVATE_KEY:
        console.error('Admin private key missing:', error.message);
        break;
      case AwSignerErrorType.ADMIN_MISSING_LIT_NETWORK:
        console.error('Lit network not specified:', error.message);
        break;
      case AwSignerErrorType.DELEGATEE_MISSING_PRIVATE_KEY:
        console.error('Delegatee private key missing:', error.message);
        break;
      case AwSignerErrorType.DELEGATEE_MISSING_LIT_NETWORK:
        console.error('Lit network not specified:', error.message);
        break;
    }
  }
}
```

## PKP Information

PKPs (Programmable Key Pairs) are represented as:

```typescript
interface PkpInfo {
  tokenId: string;              // PKP NFT token ID
  publicKey: string;            // PKP public key
  address: string;              // Ethereum address derived from public key
}
```

## Network Configuration

The package supports three Lit networks:
- `datil-dev`: Development network
- `datil-test`: Testing network
- `datil`: Production network

Each network has its own configuration for contract addresses and RPC URLs.

## Dependencies

This package depends on:
- `@lit-protocol/aw-tool`: Core tool interfaces
- `@lit-protocol/aw-tool-registry`: Tool management
- `@lit-protocol/auth-helpers`: Authentication utilities
- `@lit-protocol/contracts-sdk`: Smart contract interactions
- `@lit-protocol/lit-node-client-nodejs`: Node.js Lit client

## Credential Store

The Delegatee class implements a credential store for managing tool-specific credentials:

```typescript
// Get credentials for a tool
const { foundCredentials, missingCredentials } = await delegatee.getCredentials<T>(
  ['credential1', 'credential2']
);

// Set credentials for a tool
await delegatee.setCredentials<T>({
  credential1: 'value1',
  credential2: 'value2'
});
```

The credential store is useful for tools that require persistent configuration or authentication details.

## Need Help?

- Check out the [Agent Wallet Documentation](https://github.com/LIT-Protocol/agent-wallet)
- Visit the [Lit Protocol Documentation](https://developer.litprotocol.com/)
- Join our [Telegram](https://t.me/LitProtocol) community 