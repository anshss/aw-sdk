// Import the AwAdmin class from the '@lit-protocol/agent-wallet' package.
import { Admin as AwAdmin, type PkpInfo } from '@lit-protocol/agent-wallet';

// Import prompt utilities for user interaction.
import { promptSelectDelegateeToRemove } from '../../prompts/admin';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Removes a delegatee from the PKP.
 * This function prompts the user to select a delegatee to remove and handles the removal process.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @param pkp - The PKP to remove the delegatee from.
 */
export const handleRemoveDelegatee = async (awAdmin: AwAdmin, pkp: PkpInfo) => {
  try {
    // Get the list of delegatees.
    const delegatees = await awAdmin.getDelegatees(pkp.info.tokenId);

    // If no delegatees are found, throw an error.
    if (delegatees.length === 0) {
      throw new AwCliError(
        AwCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES,
        'No delegatees found.'
      );
    }

    // Prompt the user to select a delegatee to remove.
    const address = await promptSelectDelegateeToRemove(delegatees);

    // Log a loading message to indicate the operation is in progress.
    logger.loading('Removing delegatee...');

    // Remove the delegatee from the PKP.
    await awAdmin.removeDelegatee(pkp.info.tokenId, address);

    // Log a success message once the delegatee is removed.
    logger.success('Delegatee removed successfully.');
  } catch (error) {
    // Handle specific errors related to delegatee removal.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES) {
        // Log an error message if no delegatees are found.
        logger.error('No delegatees found.');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
