// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a delegatee from a list.
 * This function allows the user to select one delegatee from the provided list.
 *
 * @param delegatees - The list of delegatee addresses.
 * @param message - The message to display in the prompt.
 * @returns The selected delegatee address.
 * @throws AwCliError - If the user cancels the selection.
 */
export const promptSelectDelegateeFromList = async (
  delegatees: string[],
  message: string = 'Select a delegatee:'
): Promise<string> => {
  // Prompt the user to select a delegatee.
  const { delegatee } = await prompts({
    type: 'select',
    name: 'delegatee',
    message,
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