// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a delegatee.
 * This function retrieves the list of delegatees and allows the user to select one.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to get delegatees for.
 * @returns The selected delegatee address.
 * @throws AwCliError - If no delegatees are found or if the user cancels the selection.
 */
export const promptSelectDelegatee = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
): Promise<string> => {
  // Get the list of delegatees
  const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

  // If no delegatees are found, throw an error.
  if (delegatees.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_NO_DELEGATEES,
      'No delegatees found for this PKP.'
    );
  }

  // Prompt the user to select a delegatee.
  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message: 'Select a delegatee:',
    choices: delegatees.map((address) => ({
      title: address,
      value: address,
    })),
  });

  // If the user cancels the selection, throw an error.
  if (!delegatee) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SET_TOOL_POLICY_CANCELLED,
      'Delegatee selection cancelled.'
    );
  }

  return delegatee;
}; 