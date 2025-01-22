// Import the Admin class and necessary types.
import { Admin as AwAdmin, PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompts and utilities.
import { promptSelectToolForPolicy } from '../../prompts/admin/select-tool-for-policy';
import { promptSelectDelegateeFromList } from '../../prompts/admin/select-delegatee-from-list';
import { logger } from '../../utils/logger';
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the function to get tools.
import { handleGetTools } from './get-tools';

/**
 * Handles getting policy parameters for a tool and delegatee.
 * This function prompts the user to select a tool and delegatee, then retrieves the policy parameters.
 *
 * @param awAdmin - The Admin instance.
 * @param pkp - The PKP information.
 * @returns A promise that resolves when the policy parameters are retrieved.
 * @throws AwCliError - If no tools are found or if the user cancels the operation.
 */
export const handleGetPolicyParameters = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<void> => {
  try {
    // Get the list of permitted tools.
    const tools = await handleGetTools(awAdmin, pkp);
    if (!tools || (!tools.toolsWithPolicies.length && !tools.toolsWithoutPolicies.length)) {
      logger.info('No tools are currently permitted.');
      return;
    }

    // We can only get parameters for tools that have policies
    if (!tools.toolsWithPolicies.length) {
      logger.info('No tools with policies found. Please set a policy for a tool first using the "Set Tool Policy" command.');
      return;
    }

    // Prompt the user to select a tool.
    const tool = await promptSelectToolForPolicy({
      toolsWithPolicies: tools.toolsWithPolicies,
      toolsWithoutPolicies: [] // Only show tools with policies
    });

    // Get the list of delegatees.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // If no delegatees are found, log and return.
    if (!delegatees.length) {
      logger.info('No delegatees found for this PKP.');
      return;
    }

    // Prompt the user to select a delegatee.
    const delegatee = await promptSelectDelegateeFromList(delegatees, 'Select a delegatee to get policy parameters for:');

    // Check if a policy exists for this tool and delegatee
    try {
      const policy = await awAdmin.getToolPolicyForDelegatee(pkp.info.tokenId, tool.ipfsCid, delegatee);
      if (!policy.policyIpfsCid) {
        logger.info('No policy found for this tool and delegatee. Please set a policy first using the "Set Tool Policy" command.');
        return;
      }

      // Log loading message.
      logger.loading('Getting policy parameters...');

      // Get the policy parameters.
      const parameters = await awAdmin.getToolPolicyParametersForDelegatee(
        pkp.info.tokenId,
        tool.ipfsCid,
        delegatee,
        []
      );

      // Log success message with the parameters.
      logger.success('Policy parameters retrieved:');
      logger.log(JSON.stringify(parameters, null, 2));
    } catch (error) {
      if (error instanceof Error) {
        logger.info(`Could not get policy parameters: ${error.message}`);
      } else {
        logger.info('Could not get policy parameters: Unknown error occurred');
      }
    }
  } catch (error) {
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED) {
        logger.info('Policy parameter retrieval cancelled.');
        return;
      }
    }
    throw error;
  }
}; 