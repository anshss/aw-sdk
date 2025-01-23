// Import the AwAdmin type from the '@lit-protocol/agent-wallet' package.
import type { PkpInfo, Admin as AwAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';
import { promptSelectDelegateesToAdd } from '../../prompts/admin';

/**
 * Adds multiple delegatees to the Full Self-Signing (AW) system in a batch operation.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to add the delegatees for.
 * @param addresses - An array of delegatee addresses to add.
 */
const batchAddDelegatees = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  addresses: string[]
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Adding delegatees...');

  // Add the delegatees to the AW system in a batch operation.
  await awAdmin.batchAddDelegatees(pkp.info.tokenId, addresses);

  // Log a success message once the delegatees are added.
  logger.success('Successfully added delegatees.');
};

/**
 * Handles the process of adding multiple delegatees to the AW system in a batch operation.
 * This function prompts the user to select delegatee addresses, adds the delegatees,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to add the delegatees for.
 */
export const handleBatchAddDelegatee = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  try {
    // Prompt the user to select delegatee addresses.
    const addresses = await promptSelectDelegateesToAdd();

    // Add the selected delegatees to the AW system.
    await batchAddDelegatees(awAdmin, pkp, addresses);
  } catch (error) {
    // Handle specific errors related to batch delegatee addition.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED) {
        // Log an error message if the user cancels the operation.
        logger.error('Batch delegatee addition cancelled.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
