// Import the FssAdmin type from the '@lit-protocol/agent-wallet' package.
import { type Admin as FssAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptSelectDelegateesToAdd } from '../../prompts/admin';

/**
 * Adds multiple delegatees to the Full Self-Signing (FSS) system in a batch operation.
 * This function logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param addresses - An array of delegatee addresses to add.
 */
const batchAddDelegatees = async (fssAdmin: FssAdmin, addresses: string[]) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Adding delegatees...');

  // Add the delegatees to the FSS system in a batch operation.
  await fssAdmin.batchAddDelegatees(addresses);

  // Log a success message once the delegatees are added.
  logger.success('Successfully added delegatees.');
};

/**
 * Handles the process of adding multiple delegatees to the FSS system in a batch operation.
 * This function prompts the user to select delegatee addresses, adds the delegatees,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleBatchAddDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    // Prompt the user to select delegatee addresses.
    const addresses = await promptSelectDelegateesToAdd();

    // Add the selected delegatees to the FSS system.
    await batchAddDelegatees(fssAdmin, addresses);
  } catch (error) {
    // Handle specific errors related to batch delegatee addition.
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Batch delegatee addition cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
