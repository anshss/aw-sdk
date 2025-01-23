import {
  Admin as AwAdmin,
  RegisteredToolWithPolicies,
  type PkpInfo,
} from '@lit-protocol/agent-wallet';
import prompts from 'prompts';

import { handleGetTools } from './get-tools';
import { AwCliError, AwCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

const promptSelectToolToDisablePolicy = async (
  toolsWithPolicies: RegisteredToolWithPolicies[]
) => {
  // Map the tools to a list of choices for the prompts library.
  const choices = toolsWithPolicies
    .filter((tool) => !tool.toolEnabled)
    .map((tool) => ({
      title: `${tool.name} (${tool.ipfsCid})`,
      value: tool,
    }));

  // Prompt the user to select a tool.
  const { tool } = await prompts({
    type: 'select',
    name: 'tool',
    message: 'Select a tool to disable policy:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!tool) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_DISABLE_TOOL_POLICY_CANCELLED,
      'Disable tool policy cancelled.'
    );
  }

  // Return the selected tool.
  return tool as RegisteredToolWithPolicies;
};

const promptSelectToolDelegateeForPolicy = async (delegatees: string[]) => {
  // Map the delegatees to a list of choices for the prompts library.
  const choices = delegatees.map((delegatee) => ({
    title: delegatee,
    value: delegatee,
  }));

  // Prompt the user to select a delegatee.
  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message: 'Select a delegatee to disable policy:',
    choices,
  });

  // Throw an error if the user cancels the selection.
  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_DISABLE_TOOL_POLICY_CANCELLED,
      'Disable tool policy cancelled.'
    );
  }

  // Return the selected delegatee.
  return delegatee;
};

export const handleDisableToolPolicy = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  try {
    const permittedTools = await handleGetTools(awAdmin, pkp);

    if (
      permittedTools === null ||
      Object.keys(permittedTools.toolsWithPolicies).length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_DISABLE_TOOL_POLICY_NO_TOOLS_FOUND,
        'No permitted tools with policies found.'
      );
    }

    // Prompt the user to select a tool and retrieve its policy.
    const selectedTool = await promptSelectToolToDisablePolicy(
      Object.values(permittedTools.toolsWithPolicies)
    );

    await awAdmin.disableToolPolicyForDelegatee(
      pkp.info.tokenId,
      selectedTool.ipfsCid,
      await promptSelectToolDelegateeForPolicy(selectedTool.delegatees)
    );
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
    if (error instanceof AwCliError) {
      if (
        error.type === AwCliErrorType.ADMIN_DISABLE_TOOL_POLICY_NO_TOOLS_FOUND
      ) {
        // Log an error message if no permitted tools are found.
        logger.error('No permitted tools with policies found.');
        return;
      }

      if (error.type === AwCliErrorType.ADMIN_DISABLE_TOOL_POLICY_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Disable tool policy cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
