// Import the AwAdmin type from the '@lit-protocol/agent-wallet' package.
import type { PkpInfo, Admin as AwAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';
import { promptSelectDelegateesToRemove } from '../../prompts/admin';

/**
 * Removes multiple delegatees from the Full Self-Signing (AW) system in a batch operation.
 * This function logs the progress and success of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the delegatees for.
 * @param addresses - An array of delegatee addresses to remove.
 */
const batchRemoveDelegatees = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo,
  addresses: string[]
) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Removing delegatees...');

  // Remove the delegatees from the AW system in a batch operation.
  await awAdmin.batchRemoveDelegatees(pkp.info.tokenId, addresses);

  // Log a success message once the delegatees are removed.
  logger.success('Successfully removed delegatees.');
};

/**
 * Handles the process of removing multiple delegatees from the AW system in a batch operation.
 * This function prompts the user to select delegatee addresses, removes the delegatees,
 * and handles any errors that occur during the process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the delegatees for.
 */
export const handleBatchRemoveDelegatee = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  try {
    // Retrieve the current list of delegatees from the AW system.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // Prompt the user to select delegatee addresses to remove.
    const addresses = await promptSelectDelegateesToRemove(delegatees);

    // Remove the selected delegatees from the AW system.
    await batchRemoveDelegatees(awAdmin, pkp, addresses);
  } catch (error) {
    // Handle specific errors related to batch delegatee removal.
    if (error instanceof AwCliError) {
      if (
        error.type === AwCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED
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
