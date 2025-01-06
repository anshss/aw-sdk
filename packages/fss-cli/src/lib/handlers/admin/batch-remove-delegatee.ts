import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptSelectDelegateesToRemove } from '../../prompts/admin';

const batchRemoveDelegatees = async (
  fssAdmin: FssAdmin,
  addresses: string[]
) => {
  logger.loading('Removing delegatees...');
  await fssAdmin.batchRemoveDelegatees(addresses);
  logger.success('Successfully removed delegatees');
};

export const handleBatchRemoveDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    const addresses = await promptSelectDelegateesToRemove(
      await fssAdmin.getDelegatees()
    );
    await batchRemoveDelegatees(fssAdmin, addresses);
  } catch (error) {
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED
      ) {
        logger.error('Batch delegatee removal cancelled.');
        return;
      }
    }

    throw error;
  }
};
