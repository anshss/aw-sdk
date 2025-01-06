import prompts from 'prompts';

import { FssCliError, FssCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

export const promptSelectDelegateeToRemove = async (
  existingDelegatees: string[]
) => {
  if (existingDelegatees.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES,
      'No delegatees found to remove.'
    );
  }

  const { address } = await prompts({
    type: 'select',
    name: 'address',
    message: 'Select a delegatee to remove:',
    choices: existingDelegatees.map((addr) => ({
      title: addr,
      value: addr,
    })),
  });

  if (!address) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee removal cancelled.'
    );
  }

  // Show selected address and ask for confirmation
  logger.warn(`Selected delegatee to remove: ${address}`);

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Would you like to proceed with removing this delegatee?',
    initial: false,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee removal cancelled.'
    );
  }

  return address;
};
