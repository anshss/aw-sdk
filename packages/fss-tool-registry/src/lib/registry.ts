import type { FssTool } from '@lit-protocol/fss-tool';
import { SendERC20 } from '@lit-protocol/fss-tool-erc20-send';
import { SwapUniswap } from '@lit-protocol/fss-tool-swap-uniswap';
import { SigningSimple } from '@lit-protocol/fss-tool-signing-simple';

const toolRegistry = new Map<string, FssTool<any, any>>();

/**
 * Register a tool in the registry
 */
export function registerTool<T extends FssTool<any, any>>(
  name: string,
  tool: T
): void {
  toolRegistry.set(name, tool);
}

/**
 * Get a tool from the registry by name
 * @returns The tool if found, null otherwise
 */
export function getToolByName<T extends FssTool<any, any>>(
  name: string
): T | null {
  const tool = toolRegistry.get(name);
  return tool ? (tool as T) : null;
}

/**
 * Find a tool by its IPFS CID
 * @returns The tool if found, null otherwise
 */
export function getToolByIpfsCid<T extends FssTool<any, any>>(
  ipfsCid: string
): T | null {
  for (const tool of toolRegistry.values()) {
    if (tool.ipfsCid === ipfsCid) {
      return tool as T;
    }
  }
  return null;
}

/**
 * List all registered tools
 */
export function listTools(): Array<FssTool<any, any>> {
  return Array.from(toolRegistry.values());
}

registerTool('SendERC20', SendERC20);
registerTool('SwapUniswap', SwapUniswap);
registerTool('SigningSimple', SigningSimple);
