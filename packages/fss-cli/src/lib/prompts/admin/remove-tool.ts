import prompts from 'prompts';
import type { RegisteredTool } from '@lit-protocol/fss-signer';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectToolForRemoval = async (alreadyPermittedTools?: {
  toolsWithPolicies: RegisteredTool[];
  toolsWithoutPolicies: string[];
}) => {
  const choices = [
    ...(alreadyPermittedTools?.toolsWithPolicies || []).map((tool) => ({
      title: tool.ipfsCid,
      value: tool.ipfsCid,
    })),
    ...(alreadyPermittedTools?.toolsWithoutPolicies || []).map((ipfsCid) => ({
      title: ipfsCid,
      value: ipfsCid,
    })),
  ];

  if (choices.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS,
      'No permitted tools found.'
    );
  }

  const { ipfsCid } = await prompts({
    type: 'select',
    name: 'ipfsCid',
    message: 'Select a tool to remove:',
    choices,
  });

  if (!ipfsCid) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }

  return ipfsCid;
};

export const promptConfirmRemoval = async (ipfsCid: string) => {
  logger.log('');
  logger.log(`IPFS CID: ${ipfsCid}`);
  logger.log('');

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Are you sure you want to remove this tool?',
    initial: false,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_TOOL_CANCELLED,
      'Tool removal cancelled.'
    );
  }
};
