// Import the Admin class and necessary types.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompts and utilities.
import { logger } from '../../utils/logger';
import { AwCliError } from '../../errors';
import { promptSelectToolForRemoval, promptConfirmRemoval } from '../../prompts/admin/remove-tool';

/**
 * Handles the removal of a tool from the AW system.
 * @param awAdmin - The AwAdmin instance.
 * @param pkp - The PKP information.
 * @throws {AwCliError} If the user cancels the removal process.
 */
export async function handleRemoveTool(awAdmin: AwAdmin, pkp: PkpInfo) {
  try {
    // Get registered tools
    const registeredTools = await awAdmin.getRegisteredToolsAndDelegateesForPkp(pkp.info.tokenId);
    if (!registeredTools || (!Object.keys(registeredTools.toolsWithPolicies).length && !Object.keys(registeredTools.toolsWithoutPolicies).length)) {
      logger.info('No tools are currently permitted.');
      return;
    }

    // Convert RegisteredToolsResult to PermittedTools
    const permittedTools = {
      toolsWithPolicies: Object.entries(registeredTools.toolsWithPolicies).map(([ipfsCid, tool]) => ({
        ...tool,
        ipfsCid,
      })),
      toolsWithoutPolicies: Object.entries(registeredTools.toolsWithoutPolicies).map(([ipfsCid, tool]) => ({
        ...tool,
        ipfsCid,
      })),
    };

    // Prompt user to select a tool and confirm removal
    const tool = await promptSelectToolForRemoval(permittedTools);
    await promptConfirmRemoval(tool);

    // Remove the tool
    logger.info('Removing tool...');
    await awAdmin.removeTool(pkp.info.tokenId, tool.ipfsCid);
    logger.success('Tool removed successfully.');
  } catch (error) {
    if (error instanceof AwCliError) {
      throw error;
    }
    logger.error('Failed to remove tool', error as Error);
  }
}
