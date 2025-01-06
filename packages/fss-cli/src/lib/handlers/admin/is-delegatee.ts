import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';
import { promptDelegateeAddress } from '../../prompts/admin';

const checkDelegatee = async (fssAdmin: FssAdmin, address: string) => {
  logger.loading('Checking if address is a delegatee...');
  const isDelegatee = await fssAdmin.isDelegatee(address);

  if (isDelegatee) {
    logger.success(`Address ${address} is a delegatee.`);
  } else {
    logger.error(`Address ${address} is not a delegatee.`);
  }

  return isDelegatee;
};

export const handleIsDelegatee = async (fssAdmin: FssAdmin) => {
  try {
    const address = await promptDelegateeAddress();
    await checkDelegatee(fssAdmin, address);
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.ADMIN_CHECK_DELEGATEE_CANCELLED) {
        logger.error('Delegatee check cancelled.');
        return;
      }
    }

    throw error;
  }
};
