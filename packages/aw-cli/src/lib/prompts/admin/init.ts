// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Prompts the user to enter their private key for admin initialization.
 * This function ensures that the private key is provided before proceeding.
 * If the private key is not provided, the function logs an error and exits the process.
 *
 * @returns The private key entered by the user.
 */
export const promptAdminInit = async () => {
  // Prompt the user to enter their private key.
  const privateKeyResponse = await prompts({
    type: 'password', // Use a password input to hide the private key.
    name: 'privateKey',
    message: 'Enter your private key:',
  });

  // If the private key is not provided, log an error and exit the process.
  if (!privateKeyResponse.privateKey) {
    logger.error('Private key is required to proceed.');
    process.exit(1);
  }

  // Return the private key entered by the user.
  return privateKeyResponse.privateKey;
};
