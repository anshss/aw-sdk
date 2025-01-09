// Import the AwAdmin type from the '@lit-protocol/agent-wallet' package.
import { type Admin as AwAdmin } from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Retrieves the list of delegatees from the Full Self-Signing (AW) system.
 * This function logs the progress of the operation.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 * @returns A Promise that resolves to an array of delegatee addresses.
 */
const getDelegatees = async (awAdmin: AwAdmin) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting delegatees...');

  // Retrieve the list of delegatees from the AW system.
  return awAdmin.getDelegatees();
};

/**
 * Handles the process of retrieving and displaying the list of delegatees from the AW system.
 * This function logs the list of delegatees or a message if no delegatees are found.
 *
 * @param awAdmin - An instance of the AwAdmin class.
 */
export const handleGetDelegatees = async (awAdmin: AwAdmin) => {
  // Retrieve the list of delegatees from the AW system.
  const delegatees = await getDelegatees(awAdmin);

  // If no delegatees are found, log an informational message and exit.
  if (delegatees.length === 0) {
    logger.info('No delegatees found.');
    return;
  }

  // Log the list of current delegatees.
  logger.info('Current Delegatees:');
  delegatees.forEach((address) => {
    logger.log(`  - ${address}`);
  });
};
