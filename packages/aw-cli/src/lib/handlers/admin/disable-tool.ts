import {
  Admin as AwAdmin,
  RegisteredToolsResult,
  type PkpInfo,
} from '@lit-protocol/agent-wallet';
import prompts from 'prompts';

import { AwCliError, AwCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

export const promptSelectToolToDisable = async (
  permittedTools: RegisteredToolsResult
) => {
  // Combine disabled tools with and without policies into a single list of choices.
  const choices = [
    ...Object.values(permittedTools.toolsWithPolicies)
      .filter((tool) => tool.toolEnabled)
      .map((tool) => ({
        title: `${tool.name} (${tool.ipfsCid})`,
        value: tool,
      })),
    ...Object.values(permittedTools.toolsWithoutPolicies)
      .filter((tool) => tool.toolEnabled)
      .map((tool) => ({
        title: `${tool.name} (${tool.ipfsCid})`,
        value: tool,
      })),
    ...Object.keys(permittedTools.toolsUnknownWithPolicies)
      .filter(
        (ipfsCid) =>
          permittedTools.toolsUnknownWithPolicies[ipfsCid].toolEnabled
      )
      .map((ipfsCid) => ({
        title: `Unknown tool: ${ipfsCid}`,
        value: ipfsCid,
      })),
  ];

  // If no disabled tools are found, throw an error.
  if (choices.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_DISABLE_TOOL_NO_ENABLED_TOOLS,
      'No enabled tools found.'
    );
  }

  // Prompt the user to select a tool to enable.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to disable:',
    choices,
  });

  // If no tool is selected, throw an error.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_DISABLE_TOOL_CANCELLED,
      'Tool disabling cancelled.'
    );
  }

  // Return the selected tool.
  return tool;
};

export const handleDisableTool = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(
      pkp.info.tokenId
    );

    // If no permitted tools are found, throw an error.
    if (
      registeredTools === null ||
      (Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
        Object.keys(registeredTools.toolsWithoutPolicies).length === 0)
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
        'No tools are currently permitted.'
      );
    }

    const selectedTool = await promptSelectToolToDisable(registeredTools);

    await awAdmin.disableTool(pkp.info.tokenId, selectedTool.ipfsCid);
  } catch (error) {
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_DISABLE_TOOL_NO_ENABLED_TOOLS) {
        logger.error('No enabled tools found.');
        return;
      }
    }
  }
};
