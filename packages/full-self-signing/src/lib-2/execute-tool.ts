import {
  listAvailableTools,
  type ToolInfo,
} from '@lit-protocol/fss-tool-registry';

import { FssError, FssErrorType } from './errors';

async function findTool(ipfsCid: string): Promise<ToolInfo> {
  const tool = listAvailableTools().find((t) => t.ipfsCid === ipfsCid);
  if (!tool) {
    throw new FssError(
      FssErrorType.FAILED_TOOL_FIND_TOOL_IN_REGISTRY,
      'Tool not found',
      { ipfsCid }
    );
  }
  return tool;
}

export async function executeTool(ipfsCid: string) {
  const tool = await findTool(ipfsCid);
}
