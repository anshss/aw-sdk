import prompts from 'prompts';
import { ethers } from 'ethers';

import { logger } from '../../utils/logger';

/**
 * Prompts the user for a new owner's address and confirms the transfer
 * @returns The new owner's address if confirmed, null if cancelled
 */
export const promptNewPkpOwner = async (pkpEthAddress: string) => {
  const { address } = await prompts({
    type: 'text',
    name: 'address',
    message: "Enter the new owner's Ethereum address:",
    validate: (value) => {
      try {
        ethers.utils.getAddress(value); // Validates the address format
        return true;
      } catch {
        return 'Please enter a valid Ethereum address';
      }
    },
  });

  if (!address) {
    logger.error('No address provided');
    process.exit(1);
  }

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: `Are you sure you want to transfer ownership of ${pkpEthAddress} to ${address}? This action cannot be undone.`,
    initial: false,
  });

  if (!confirmed) {
    return null;
  }

  return ethers.utils.getAddress(address);
};
