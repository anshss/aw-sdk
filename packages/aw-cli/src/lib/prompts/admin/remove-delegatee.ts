// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to select a delegatee to remove from a list of existing delegatees.
 * This function validates the input, confirms the selection, and handles errors such as
 * no delegatees being available or the user cancelling the operation.
 *
 * @param existingDelegatees - An array of existing delegatee addresses.
 * @returns The selected delegatee address for removal.
 * @throws FssCliError - If no delegatees are available, no delegatee is selected, or the user cancels the operation.
 */
export const promptSelectDelegateeToRemove = async (
  existingDelegatees: string[]
) => {
  // If no delegatees are available, throw an error.
  if (existingDelegatees.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES,
      'No delegatees found to remove.'
    );
  }

  // Prompt the user to select a delegatee to remove.
  const { address } = await prompts({
    type: 'select',
    name: 'address',
    message: 'Select a delegatee to remove:',
    choices: existingDelegatees.map((addr) => ({
      title: addr,
      value: addr,
    })),
  });

  // If no delegatee is selected, throw an error.
  if (!address) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee removal cancelled.'
    );
  }

  // Display the selected delegatee and ask for confirmation.
  logger.warn(`Selected delegatee to remove: ${address}`);

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Would you like to proceed with removing this delegatee?',
    initial: false,
  });

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee removal cancelled.'
    );
  }

  // Return the selected delegatee address for removal.
  return address;
};
