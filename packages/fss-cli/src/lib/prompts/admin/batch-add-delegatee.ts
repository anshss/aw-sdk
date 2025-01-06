import prompts from 'prompts';
import { ethers } from 'ethers';

import { FssCliError, FssCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

export const promptSelectDelegateesToAdd = async () => {
  const addresses: string[] = [];

  logger.info('Enter delegatee addresses:');
  logger.log('(Press Enter without a value when done)\n');

  while (true) {
    const { address } = await prompts({
      type: 'text',
      name: 'address',
      message: `Enter delegatee address (${addresses.length + 1}):`,
      validate: (value) => {
        if (!value) return true; // Allow empty for completion
        try {
          ethers.utils.getAddress(value);
          return true;
        } catch {
          return 'Invalid Ethereum address';
        }
      },
    });

    if (!address) {
      if (addresses.length === 0) {
        const { confirmed } = await prompts({
          type: 'confirm',
          name: 'confirmed',
          message: 'No addresses entered. Do you want to cancel?',
          initial: true,
        });
        if (confirmed) {
          throw new FssCliError(
            FssCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED,
            'Batch delegatee addition cancelled.'
          );
        }
        continue;
      }
      break;
    }

    const normalizedAddress = ethers.utils.getAddress(address);
    addresses.push(normalizedAddress);
  }

  // Show addresses and ask for confirmation
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

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_BATCH_ADD_DELEGATEE_CANCELLED,
      'Batch delegatee addition cancelled.'
    );
  }

  return addresses;
};
