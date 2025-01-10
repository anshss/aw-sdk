# @lit-protocol/aw-tool-registry

Use this package to manage and access tools that your AI Agents can execute. The Tool Registry helps you register, discover, and validate tools across different Lit networks.

## What You Can Do

- Register tools with their IPFS CIDs and metadata
- Look up tools by name or IPFS CID
- Manage which tools are available on different networks
- Get tool metadata and execution information
- List all available tools for a specific network

## Installation

```bash
pnpm add @lit-protocol/aw-tool-registry
```

## Built-in Tools

We provide several tools out of the box:
- `ERC20Transfer`: Transfer ERC20 tokens
- `UniswapSwap`: Execute Uniswap swaps
- `SignEcdsa`: Perform ECDSA signing operations

These tools are automatically registered when you import the package.

## Usage Examples

```typescript
import { 
  getToolByName, 
  getToolByIpfsCid, 
  listToolsByNetwork,
  type LitNetwork 
} from '@lit-protocol/aw-tool-registry';

// Looking up a tool by IPFS CID (commonly used by the signer)
const toolByCid = getToolByIpfsCid('QmYourIpfsCid');
if (toolByCid) {
  const { tool, network } = toolByCid;
  // Access tool metadata, parameters, policies
  console.log(tool.name, tool.description);
}

// Listing tools for a network (used by CLI for tool selection)
const network: LitNetwork = 'datil-dev';
const networkTools = listToolsByNetwork(network);
networkTools.forEach(tool => {
  console.log(`${tool.name}: ${tool.description}`);
});

// Getting a specific tool (used for policy management)
const erc20Tool = getToolByName('ERC20Transfer', network);
if (erc20Tool) {
  // Access tool's policy definitions
  const policy = erc20Tool.policy;
}
```

## Adding a New Tool to the Registry

To add a new tool to the registry, follow these steps:

1. Add the tool package as a dependency in `package.json`:
```json
{
  "dependencies": {
    "@lit-protocol/aw-tool": "workspace:*",
    "@lit-protocol/aw-tool-your-tool": "workspace:*"  // Your new tool
  }
}
```

2. Import the tool in `src/lib/registry.ts`:
```typescript
import type { AwTool } from '@lit-protocol/aw-tool';
import { YourTool } from '@lit-protocol/aw-tool-your-tool';
```

3. Register the tool at the bottom of `registry.ts`:
```typescript
registerTool('YourTool', YourTool);
```

That's it! The tool will now be available through all registry functions like `getToolByName`, `listToolsByNetwork`, etc.

Note: Your tool package must implement the `AwTool` interface from `@lit-protocol/aw-tool`. For information on creating a new tool package, refer to the [Agent Wallet Documentation](https://github.com/LIT-Protocol/agent-wallet).

## Dependencies

This package builds on:
- `@lit-protocol/aw-tool`: Core interfaces and types
- `@lit-protocol/aw-tool-erc20-transfer`: ERC20 transfer implementation
- `@lit-protocol/aw-tool-uniswap-swap`: Uniswap swap implementation
- `@lit-protocol/aw-tool-sign-ecdsa`: ECDSA signing implementation

## Need Help?

- Check out the [Agent Wallet Documentation](https://github.com/LIT-Protocol/agent-wallet)
- Visit the [Lit Protocol Documentation](https://developer.litprotocol.com/)
- Join our [Telegram](https://t.me/LitProtocol) community
