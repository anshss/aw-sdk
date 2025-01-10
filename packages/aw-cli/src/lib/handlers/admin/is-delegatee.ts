// Import the AwAdmin type from the '@lit-protocol/agent-wallet' package.
import type { PkpInfo, Admin as AwAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

/**
 * Checks if a given address is a delegatee in the Full Self-Signing (AW) system.
 * This function logs the result of the check.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to check if the address is a delegatee for.
 * @param address - The address to check.
 * @returns A Promise that resolves to a boolean indicating whether the address is a delegatee.
 */
const checkDelegatee = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  address: string
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Checking if address is a delegatee...');

  // Check if the address is a delegatee in the AW system.
  const isDelegatee = await awAdmin.isDelegatee(pkp.info.tokenId, address);

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
 * Handles the process of checking if an address is a delegatee in the AW system.
 * This function prompts the user for the address, checks if it is a delegatee,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to check if the address is a delegatee for.
 */
export const handleIsDelegatee = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Prompt the user for the delegatee's address.
    const address = await promptDelegateeAddress();

    // Check if the address is a delegatee.
    await checkDelegatee(awAdmin, pkp, address);
  } catch (error) {
    // Handle specific errors related to delegatee checking.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Delegatee check cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
