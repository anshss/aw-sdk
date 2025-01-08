// Import the FssAdmin type from the '@lit-protocol/full-self-signing' package.
import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the prompt utility for selecting a delegatee to remove.
import { promptSelectDelegateeToRemove } from '../../prompts/admin';

/**
 * Removes a delegatee from the Full Self-Signing (FSS) system.
 * This function logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param address - The address of the delegatee to remove.
 */
const removeDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing delegatee...');

  // Remove the delegatee from the FSS system.
  await fssAdmin.removeDelegatee(address);

  // Log a success message once the delegatee is removed.
  logger.success(`Successfully removed delegatee: ${address}`);
};

/**
 * Handles the process of removing a delegatee from the FSS system.
 * This function retrieves the list of delegatees, prompts the user to select a delegatee to remove,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleRemoveDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the list of delegatees from the FSS system.
    const delegatees = await fssAdmin.getDelegatees();

    // Prompt the user to select a delegatee to remove.
    const address = await promptSelectDelegateeToRemove(delegatees);

    // Remove the selected delegatee from the FSS system.
    await removeDelegatee(fssAdmin, address);
  } catch (error) {
    // Handle specific errors related to delegatee removal.
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED
      ) {
        // Log an error message if the user cancels the operation.
        logger.error('Delegatee removal cancelled.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES) {
        // Log an error message if no delegatees are found.
        logger.error('No delegatees found to remove.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
