import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';
import prompts from 'prompts';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { handleGetTools } from './get-tools';
import { promptPolicyDetails } from '../../prompts/admin';

const promptSelectToolForPolicy = async (permittedTools: {
  toolsWithPolicies: Array<{ ipfsCid: string }>;
  toolsWithoutPolicies: string[];
}) => {
  const choices = [
    ...permittedTools.toolsWithPolicies.map((tool) => ({
      title: tool.ipfsCid,
      description: 'Update existing policy',
      value: tool.ipfsCid,
    })),
    ...permittedTools.toolsWithoutPolicies.map((ipfsCid) => ({
      title: ipfsCid,
      description: 'Set new policy',
      value: ipfsCid,
    })),
  ];

  const { ipfsCid } = await prompts({
    type: 'select',
    name: 'ipfsCid',
    message: 'Select a tool to set the policy for:',
    choices,
  });

  if (!ipfsCid) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Tool policy setting cancelled.'
    );
  }

  return ipfsCid;
};

const setToolPolicy = async (
  fssAdmin: FssAdmin,
  ipfsCid: string,
  policy: string,
  version: string
) => {
  logger.loading('Setting tool policy...');
  await fssAdmin.setToolPolicy(ipfsCid, policy, version);
  logger.success('Tool policy set successfully.');
};

export const handleSetToolPolicy = async (fssAdmin: FssAdmin) => {
  try {
    const permittedTools = await handleGetTools(fssAdmin);

    if (
      permittedTools === undefined ||
      (permittedTools.toolsWithPolicies.length === 0 &&
        permittedTools.toolsWithoutPolicies.length === 0)
    ) {
      throw new FssCliError(
        FssCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS,
        'No tools are currently permitted.'
      );
    }

    const selectedTool = await promptSelectToolForPolicy(permittedTools);
    const { policy, version } = await promptPolicyDetails(selectedTool);
    await setToolPolicy(fssAdmin, selectedTool, policy, version);
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_SET_TOOL_POLICY_NO_TOOLS) {
        logger.error('No permitted tools found.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        logger.error('Tool policy setting cancelled.');
        return;
      }
    }

    throw error;
  }
};
