import {
  type FssTool,
  type Admin as FssAdmin,
} from '@lit-protocol/full-self-signing';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { handleGetTools } from './get-tools';

const promptConfirmPolicyRemoval = async (tool: FssTool<any, any>) => {
  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: `Are you sure you want to remove the policy for tool ${tool.name} (${tool.ipfsCid})?`,
    initial: false,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED,
      'Tool policy removal cancelled.'
    );
  }
};

const promptSelectToolForPolicyRemoval = async (
  toolsWithPolicies: FssTool<any, any>[]
) => {
  const choices = toolsWithPolicies.map((tool) => ({
    title: `${tool.name} (${tool.ipfsCid})`,
    value: tool,
  }));

  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to remove policy:',
    choices,
  });

  if (!tool) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED,
      'Tool policy removal cancelled.'
    );
  }

  await promptConfirmPolicyRemoval(tool);

  return tool;
};

const removeToolPolicy = async (
  fssAdmin: FssAdmin,
  tool: FssTool<any, any>
) => {
  logger.loading('Removing tool policy...');
  await fssAdmin.removeToolPolicy(tool.ipfsCid);
  logger.success('Tool policy removed successfully.');
};

export const handleRemoveToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await handleGetTools(fssAdmin);

    if (permittedTools === null) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS,
        'No tools with policies found.'
      );
    }

    await removeToolPolicy(
      fssAdmin,
      await promptSelectToolForPolicyRemoval(permittedTools.toolsWithPolicies)
    );
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS) {
        logger.error('No tools with policies found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_REMOVE_TOOL_POLICY_CANCELLED) {
        logger.error('Tool policy removal cancelled.');
        return;
      }
    }

    throw error;
  }
};
