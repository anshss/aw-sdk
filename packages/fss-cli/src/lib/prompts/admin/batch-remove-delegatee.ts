import prompts from 'prompts';

import { FssCliError, FssCliErrorType } from '../../errors';
import { logger } from '../../utils/logger';

export const promptSelectDelegateesToRemove = async (
  existingDelegatees: string[]
) => {
  if (existingDelegatees.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_NO_DELEGATEES,
      'No delegatees found to remove.'
    );
  }

  const { selectedAddresses } = await prompts({
    type: 'multiselect',
    name: 'selectedAddresses',
    message: 'Select delegatees to remove (space to select, enter to confirm):',
    choices: existingDelegatees.map((addr) => ({
      title: addr,
      value: addr,
    })),
    hint: '- Space to select, Return to submit',
    instructions: false,
  });

  if (!selectedAddresses || selectedAddresses.length === 0) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED,
      'No delegatees selected for removal.'
    );
  }

  // Show selected addresses and ask for confirmation
  logger.warn('Selected delegatees to remove:');
  selectedAddresses.forEach((addr: string, i: number) => {
    logger.log(`  ${i + 1}. ${addr}`);
  });

  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: 'Would you like to proceed with removing these delegatees?',
    initial: false,
  });

  if (!confirmed) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED,
      'Batch delegatee removal cancelled.'
    );
  }

  return selectedAddresses;
};
