// Import the FssAdmin type from the '@lit-protocol/full-self-signing' package.
import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Retrieves the list of delegatees from the Full Self-Signing (FSS) system.
 * This function logs the progress of the operation.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 * @returns A Promise that resolves to an array of delegatee addresses.
 */
const getDelegatees = async (fssAdmin: FssAdmin) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting delegatees...');

  // Retrieve the list of delegatees from the FSS system.
  return fssAdmin.getDelegatees();
};

/**
 * Handles the process of retrieving and displaying the list of delegatees from the FSS system.
 * This function logs the list of delegatees or a message if no delegatees are found.
 *
 * @param fssAdmin - An instance of the FssAdmin class.
 */
export const handleGetDelegatees = async (fssAdmin: FssAdmin) => {
  // Retrieve the list of delegatees from the FSS system.
  const delegatees = await getDelegatees(fssAdmin);

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
