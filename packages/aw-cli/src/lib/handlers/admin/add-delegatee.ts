// Import the FssAdmin type from the '@lit-protocol/agent-wallet' package.
import { type Admin as FssAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

/**
 * Adds a delegatee to the Full Self-Signing (FSS) system.
 * This function logs the progress and success of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param address - The address of the delegatee to add.
 */
const addDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Adding delegatee...');

  // Add the delegatee to the FSS system.
  await fssAdmin.addDelegatee(address);

  // Log a success message once the delegatee is added.
  logger.success(`Successfully added delegatee ${address}.`);
};

/**
 * Handles the process of adding a delegatee to the FSS system.
 * This function prompts the user for the delegatee's address, adds the delegatee,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleAddDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    // Prompt the user for the delegatee's address.
    const address = await promptDelegateeAddress();

    // Add the delegatee to the FSS system.
    await addDelegatee(fssAdmin, address);
  } catch (error) {
    // Handle specific errors related to delegatee addition.
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED
      ) {
        // Log an error message if the user cancels the operation.
        logger.error('Delegatee addition cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
