// Import the AwAdmin type from the '@lit-protocol/agent-wallet' package.
import type { PkpInfo, Admin as AwAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

/**
 * Adds a delegatee to the Full Self-Signing (AW) system.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to add the delegatee for.
 * @param address - The address of the delegatee to add.
 */
const addDelegatee = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  address: string
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Adding delegatee...');

  // Add the delegatee to the AW system.
  await awAdmin.addDelegatee(pkp.info.tokenId, address);

  // Log a success message once the delegatee is added.
  logger.success(`Successfully added delegatee ${address}.`);
};

/**
 * Handles the process of adding a delegatee to the AW system.
 * This function prompts the user for the delegatee's address, adds the delegatee,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to add the delegatee for.
 */
export const handleAddDelegatee = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Prompt the user for the delegatee's address.
    const address = await promptDelegateeAddress();

    // Add the delegatee to the AW system.
    await addDelegatee(awAdmin, pkp, address);
  } catch (error) {
    // Handle specific errors related to delegatee addition.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Delegatee addition cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
