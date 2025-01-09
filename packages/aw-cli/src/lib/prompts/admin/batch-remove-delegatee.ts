// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to select delegatees for removal from a list of existing delegatees.
 * This function validates the input, confirms the selection, and handles errors such as
 * no delegatees being available or the user cancelling the operation.
 *
 * @param existingDelegatees - An array of existing delegatee addresses.
 * @returns An array of selected delegatee addresses for removal.
 * @throws AwCliError - If no delegatees are available, no delegatees are selected, or the user cancels the operation.
 */
export const promptSelectDelegateesToRemove = async (
  existingDelegatees: string[]
) => {
  // If no delegatees are available, throw an error.
  if (existingDelegatees.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_NO_DELEGATEES,
      'No delegatees found to remove.'
    );
  }

  // Prompt the user to select delegatees for removal.
  const { selectedAddresses } = await prompts({
    type: 'multiselect',
    name: 'selectedAddresses',
    message: 'Select delegatees to remove (space to select, enter to confirm):',
    choices: existingDelegatees.map((addr) => ({
      title: addr,
      value: addr,
    })),
    hint: '- Space to select, Return to submit',
    instructions: false,
  });

  // If no delegatees are selected, throw an error.
  if (!selectedAddresses || selectedAddresses.length === 0) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED,
      'No delegatees selected for removal.'
    );
  }

  // Display the selected delegatees and ask for confirmation.
  logger.warn('Selected delegatees to remove:');
  selectedAddresses.forEach((addr: string, i: number) => {
    logger.log(`  ${i + 1}. ${addr}`);
  });

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Would you like to proceed with removing these delegatees?',
    initial: false,
  });

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED,
      'Batch delegatee removal cancelled.'
    );
  }

  // Return the list of selected delegatee addresses for removal.
  return selectedAddresses;
};
