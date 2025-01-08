// Import the FssAdmin type from the '@lit-protocol/full-self-signing' package.
import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptSelectDelegateesToRemove } from '../../prompts/admin';

/**
 * Removes multiple delegatees from the Full Self-Signing (FSS) system in a batch operation.
 * This function logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param addresses - An array of delegatee addresses to remove.
 */
const batchRemoveDelegatees = async (
  fssAdmin: FssAdmin,
  addresses: string[]
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing delegatees...');

  // Remove the delegatees from the FSS system in a batch operation.
  await fssAdmin.batchRemoveDelegatees(addresses);

  // Log a success message once the delegatees are removed.
  logger.success('Successfully removed delegatees.');
};

/**
 * Handles the process of removing multiple delegatees from the FSS system in a batch operation.
 * This function prompts the user to select delegatee addresses, removes the delegatees,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleBatchRemoveDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    // Retrieve the current list of delegatees from the FSS system.
    const delegatees = await fssAdmin.getDelegatees();

    // Prompt the user to select delegatee addresses to remove.
    const addresses = await promptSelectDelegateesToRemove(delegatees);

    // Remove the selected delegatees from the FSS system.
    await batchRemoveDelegatees(fssAdmin, addresses);
  } catch (error) {
    // Handle specific errors related to batch delegatee removal.
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED
      ) {
        // Log an error message if the user cancels the operation.
        logger.error('Batch delegatee removal cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
