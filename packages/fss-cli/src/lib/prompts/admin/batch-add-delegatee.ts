// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the ethers library for Ethereum address validation.
import { ethers } from 'ethers';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to enter delegatee addresses, validates them, and confirms the list before proceeding.
 * This function handles user cancellation and ensures proper Ethereum address formatting.
 *
 * @returns An array of validated and normalized Ethereum addresses.
 * @throws FssCliError - If the user cancels the operation.
 */
export const promptSelectDelegateesToAdd = async () => {
  // Initialize an array to store the entered delegatee addresses.
  const addresses: string[] = [];

  // Log instructions for the user.
  logger.info('Enter delegatee addresses:');
  logger.log('(Press Enter without a value when done)\n');

  // Continuously prompt the user to enter delegatee addresses.
  while (true) {
    const { address } = await prompts({
      type: 'text',
      name: 'address',
      message: `Enter delegatee address (${addresses.length + 1}):`,
      validate: (value) => {
        // Allow empty input to indicate completion.
        if (!value) return true;

        // Validate the Ethereum address format.
        try {
          ethers.utils.getAddress(value);
          return true;
        } catch {
          return 'Invalid Ethereum address';
        }
      },
    });

    // If the user presses Enter without entering an address, check if the list is empty.
    if (!address) {
      if (addresses.length === 0) {
        // Prompt the user to confirm cancellation if no addresses were entered.
        const { confirmed } = await prompts({
          type: 'confirm',
          name: 'confirmed',
          message: 'No addresses entered. Do you want to cancel?',
          initial: true,
        });

        // If the user confirms cancellation, throw an error.
        if (confirmed) {
          throw new FssCliError(
            FssCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED,
            'Batch delegatee addition cancelled.'
          );
        }

        // Continue prompting if the user does not confirm cancellation.
        continue;
      }

      // Exit the loop if the user is done entering addresses.
      break;
    }

    // Normalize the Ethereum address and add it to the list.
    const normalizedAddress = ethers.utils.getAddress(address);
    addresses.push(normalizedAddress);
  }

  // Display the entered addresses and ask for confirmation.
  logger.warn('Adding delegatee addresses:');
  addresses.forEach((addr, i) => {
    logger.log(`  ${i + 1}. ${addr}`);
  });

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Would you like to proceed with these addresses?',
    initial: false,
  });

  // If the user does not confirm, throw an error.
  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED,
      'Batch delegatee addition cancelled.'
    );
  }

  // Return the list of validated and normalized addresses.
  return addresses;
};
