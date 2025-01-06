import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptSelectDelegateeToRemove } from '../../prompts/admin';

const removeDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  logger.loading('Removing delegatee...');
  await fssAdmin.removeDelegatee(address);
  logger.success(`Successfully removed delegatee: ${address}`);
};

export const handleRemoveDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    const address = await promptSelectDelegateeToRemove(
      await fssAdmin.getDelegatees()
    );
    await removeDelegatee(fssAdmin, address);
  } catch (error) {
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED
      ) {
        logger.error('Delegatee removal cancelled.');
        return;
      }

      if (error.type === FssCliErrorType.ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES) {
        logger.error('No delegatees found to remove.');
        return;
      }
    }

    throw error;
  }
};
