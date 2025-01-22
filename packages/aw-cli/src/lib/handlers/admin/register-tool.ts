// Import the Admin class and necessary types.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';
import { listAllTools } from '@lit-protocol/aw-tool-registry';

// Import prompts and utilities.
import prompts from 'prompts';
import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a tool from the available tools in the registry.
 * @returns A promise that resolves to the selected tool's IPFS CID.
 * @throws {AwCliError} If the user cancels the prompt or no tools are available.
 */
async function promptSelectTool(network: string): Promise<string> {
  const allTools = listAllTools();
  const tools = allTools.filter(t => t.network === network);
  
  if (!tools.length) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS,
      `No tools available in the registry for network ${network}.`
    );
  }

  logger.info('Registering a tool will:');
  logger.log('1. Add the tool to the PKP on-chain');
  logger.log('2. Mark the tool as permitted for use');
  logger.log('');

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to register:',
    choices: tools.map((t) => ({
      title: t.tool.name,
      value: t.tool.ipfsCid,
      description: t.tool.description || undefined,
    })),
  });

  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool registration cancelled.'
    );
  }

  return tool;
}

/**
 * Prompts the user to confirm if the tool should be enabled initially.
 * @returns A promise that resolves to a boolean indicating if the tool should be enabled.
 * @throws {AwCliError} If the user cancels the prompt.
 */
async function promptToolEnabled(): Promise<boolean> {
  logger.info('Enabling a tool:');
  logger.log('- Controls whether the tool can be used right now');
  logger.log('- Can be changed later with enable/disable commands');
  logger.log('- Is separate from policy-level enabling per delegatee');
  logger.log('');

  const { enabled } = await prompts({
    type: 'confirm',
    name: 'enabled',
    message: 'Enable this tool initially?',
    initial: true,
  });

  if (enabled === undefined) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PERMIT_TOOL_CANCELLED,
      'Tool registration cancelled.'
    );
  }

  return enabled;
}

/**
 * Handles the registration of a tool in the AW system.
 * @param awAdmin - The AwAdmin instance.
 * @param pkp - The PKP information.
 * @throws {AwCliError} If the user cancels the registration process or no tools are available.
 */
export async function handleRegisterTool(awAdmin: AwAdmin, pkp: PkpInfo) {
  try {
    // Prompt user to select a tool from the registry for the current network
    const ipfsCid = await promptSelectTool(awAdmin.litNetwork);

    // Prompt for enabling the tool
    const enabled = await promptToolEnabled();

    // Register the tool
    logger.info('Registering tool...');
    await awAdmin.registerTool(pkp.info.tokenId, ipfsCid, { enableTools: enabled });
    logger.success('Tool registered successfully.');
  } catch (error) {
    if (error instanceof AwCliError) {
      throw error;
    }
    logger.error('Failed to register tool', error as Error);
  }
} 