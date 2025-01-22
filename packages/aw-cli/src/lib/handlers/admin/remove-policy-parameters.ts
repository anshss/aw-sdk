// Import the Admin class and necessary types.
import { Admin as AwAdmin, PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompts and utilities.
import { promptSelectToolForPolicy } from '../../prompts/admin/select-tool-for-policy';
import { promptSelectDelegateeFromList } from '../../prompts/admin/select-delegatee-from-list';
import { promptPolicyParameterNames } from '../../prompts/admin/select-policy-parameters';
import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the function to get tools.
import { handleGetTools } from './get-tools';

/**
 * Handles removing policy parameters for a tool and delegatee.
 * This function prompts the user to select a tool and delegatee, then removes the policy parameters.
 *
 * @param awAdmin - The Admin instance.
 * @param pkp - The PKP information.
 * @returns A promise that resolves when the policy parameters are removed.
 * @throws AwCliError - If no tools are found or if the user cancels the operation.
 */
export const handleRemovePolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<void> => {
  try {
    // Get the list of permitted tools.
    const tools = await handleGetTools(awAdmin, pkp);
    if (!tools || (!tools.toolsWithPolicies.length && !tools.toolsWithoutPolicies.length)) {
      return;
    }

    // Prompt the user to select a tool.
    const tool = await promptSelectToolForPolicy(tools);

    // Get the list of delegatees.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // If no delegatees are found, log and return.
    if (!delegatees.length) {
      logger.error('No delegatees found for this PKP.');
      return;
    }

    // Prompt the user to select a delegatee.
    const delegatee = await promptSelectDelegateeFromList(delegatees, 'Select a delegatee to remove policy parameters for:');

    // Prompt for parameter names to remove.
    const parameterNames = await promptPolicyParameterNames();

    // Log loading message.
    logger.loading('Removing policy parameters...');

    // Remove the policy parameters.
    await awAdmin.removeToolPolicyParametersForDelegatee(
      pkp.info.tokenId,
      tool.ipfsCid,
      delegatee,
      parameterNames
    );

    // Log success message.
    logger.success('Policy parameters removed successfully.');
  } catch (error) {
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        logger.error('Policy parameter removal cancelled.');
        return;
      }
    }
    throw error;
  }
}; 