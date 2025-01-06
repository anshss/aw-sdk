import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

const addDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  logger.loading('Adding delegatee...');
  await fssAdmin.addDelegatee(address);
  logger.success(`Successfully added delegatee ${address}.`);
};

export const handleAddDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    const address = await promptDelegateeAddress();
    await addDelegatee(fssAdmin, address);
  } catch (error) {
    if (error instanceof FssCliError) {
      if (
        error.type === FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED
      ) {
        logger.error('Delegatee addition cancelled.');
        return;
      }
    }

    throw error;
  }
};
