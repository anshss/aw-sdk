import { FssTool } from '@lit-protocol/fss-tool';
import { SendERC20 } from '@lit-protocol/fss-tool-erc20-send';

import { FssToolRegistryError, FssToolRegistryErrorType } from './errors';

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
 * Get a tool from the registry
 * @throws RegistryError if tool is not found
 */
export function getToolByName<T extends FssTool<any, any>>(name: string): T {
  const tool = toolRegistry.get(name);
  if (!tool) {
    throw new FssToolRegistryError(
      FssToolRegistryErrorType.TOOL_NOT_FOUND,
      `Tool not found: ${name}`,
      { name }
    );
  }
  return tool as T;
}

/**
 * Find a tool by its IPFS CID
 * @throws RegistryError if tool is not found
 */
export function getToolByIpfsCid<T extends FssTool<any, any>>(
  ipfsCid: string
): T {
  for (const tool of toolRegistry.values()) {
    if (tool.ipfsCid === ipfsCid) {
      return tool as T;
    }
  }
  throw new FssToolRegistryError(
    FssToolRegistryErrorType.IPFS_CID_NOT_FOUND,
    `No tool found with IPFS CID: ${ipfsCid}`,
    { ipfsCid }
  );
}

/**
 * Check if a tool exists in the registry
 */
export function hasTool(name: string): boolean {
  return toolRegistry.has(name);
}

/**
 * List all registered tools
 */
export function listTools(): Array<FssTool<any, any>> {
  return Array.from(toolRegistry.values());
}

registerTool('SendERC20', SendERC20);
