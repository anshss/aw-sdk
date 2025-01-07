// Import the FssAdmin type from the '@lit-protocol/full-self-signing' package.
import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

/**
 * Checks if a given address is a delegatee in the Full Self-Signing (FSS) system.
 * This function logs the result of the check.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @param address - The address to check.
 * @returns A Promise that resolves to a boolean indicating whether the address is a delegatee.
 */
const checkDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Checking if address is a delegatee...');

  // Check if the address is a delegatee in the FSS system.
  const isDelegatee = await fssAdmin.isDelegatee(address);

  // Log the result of the check.
  if (isDelegatee) {
    logger.success(`Address ${address} is a delegatee.`);
  } else {
    logger.error(`Address ${address} is not a delegatee.`);
  }

  // Return the result of the check.
  return isDelegatee;
};

/**
 * Handles the process of checking if an address is a delegatee in the FSS system.
 * This function prompts the user for the address, checks if it is a delegatee,
 * and handles any errors that occur during the process.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleIsDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    // Prompt the user for the delegatee's address.
    const address = await promptDelegateeAddress();

    // Check if the address is a delegatee.
    await checkDelegatee(fssAdmin, address);
  } catch (error) {
    // Handle specific errors related to delegatee checking.
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED
      ) {
        // Log an error message if the user cancels the operation.
        logger.error('Delegatee check cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
