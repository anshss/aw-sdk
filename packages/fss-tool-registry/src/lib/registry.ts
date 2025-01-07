import type { FssTool } from '@lit-protocol/fss-tool';
import { SendERC20 } from '@lit-protocol/fss-tool-erc20-send';
import { SwapUniswap } from '@lit-protocol/fss-tool-swap-uniswap';
import { SignEcdsa } from '@lit-protocol/fss-tool-sign-ecdsa';

export type LitNetwork = 'datil-dev' | 'datil-test' | 'datil';

export type NetworkSpecificTool<T extends FssTool<any, any>> = Record<
  LitNetwork,
  T
>;

export type PermittedTools = {
  toolsWithPolicies: FssTool<any, any>[];
  toolsWithoutPolicies: FssTool<any, any>[];
};

const toolRegistry = new Map<string, NetworkSpecificTool<FssTool<any, any>>>();

/**
 * Register a tool in the registry
 */
export function registerTool<T extends FssTool<any, any>>(
  name: string,
  tool: NetworkSpecificTool<T>
): void {
  toolRegistry.set(name, tool);
}

/**
 * Get a tool from the registry by name and network
 * @returns The tool if found, null otherwise
 */
export function getToolByName<T extends FssTool<any, any>>(
  name: string,
  network: LitNetwork
): T | null {
  const tool = toolRegistry.get(name);
  if (!tool) return null;
  return tool[network] as T;
}

/**
 * Find a tool by its IPFS CID
 * @returns The tool and its network if found, null otherwise
 */
export function getToolByIpfsCid<T extends FssTool<any, any>>(
  ipfsCid: string
): { tool: T; network: LitNetwork } | null {
  for (const [, networkTools] of toolRegistry.entries()) {
    for (const [network, tool] of Object.entries(networkTools)) {
      if (tool.ipfsCid === ipfsCid) {
        return {
          tool: tool as T,
          network: network as LitNetwork,
        };
      }
    }
  }
  return null;
}

/**
 * List all registered tools for a specific network
 */
export function listToolsByNetwork<T extends FssTool<any, any>>(
  network: LitNetwork
): Array<T> {
  return Array.from(toolRegistry.values()).map(
    (networkTools) => networkTools[network] as T
  );
}

/**
 * List all registered tools for all networks
 */
export function listAllTools<T extends FssTool<any, any>>(): Array<{
  tool: T;
  network: LitNetwork;
}> {
  const tools: Array<{ tool: T; network: LitNetwork }> = [];

  for (const networkTools of toolRegistry.values()) {
    for (const [network, tool] of Object.entries(networkTools)) {
      tools.push({
        tool: tool as T,
        network: network as LitNetwork,
      });
    }
  }

  return tools;
}

// Register the SendERC20 tool
registerTool('SendERC20', SendERC20);
registerTool('SwapUniswap', SwapUniswap);
registerTool('SignEcdsa', SignEcdsa);
