// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Handles the case where the delegatee wallet has an insufficient balance of Lit test tokens.
 * This function informs the user about the issue, provides instructions for funding the wallet,
 * and prompts the user to confirm whether they have funded their wallet.
 *
 * @returns A boolean indicating whether the user has confirmed funding their wallet.
 *   - `true` if the user confirms they have funded their wallet.
 *   - `false` if the user does not confirm or cancels the operation.
 */
export const promptDelegateeInsufficientBalance = async () => {
  // Log an error message indicating insufficient Lit test token balance.
  logger.error(
    'Insufficient Lit test token balance to mint Lit Capacity Credit.'
  );

  // Provide instructions for funding the wallet with Lit test tokens.
  logger.info(
    'Please fund your wallet with Lit test tokens from: https://chronicle-yellowstone-faucet.getlit.dev/'
  );

  // Prompt the user to confirm whether they have funded their wallet.
  const fundingResponse = await prompts({
    type: 'confirm',
    name: 'hasFunded',
    message: 'Have you funded your Delegatee wallet with Lit test tokens?',
    initial: false,
  });

  // If the user confirms they have funded their wallet, return `true`.
  if (fundingResponse.hasFunded) {
    return true;
  }

  // If the user does not confirm, log an error message and return `false`.
  logger.error(
    'Lit test tokens are required for minting PKPs and registering policies. Please fund your wallet and try again.'
  );
  return false;
};
