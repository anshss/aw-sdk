import { type Admin as FssAdmin } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

const getDelegatees = async (fssAdmin: FssAdmin) => {
  logger.loading('Getting delegatees...');
  return fssAdmin.getDelegatees();
};

export const handleGetDelegatees = async (fssAdmin: FssAdmin) => {
  const delegatees = await getDelegatees(fssAdmin);

  if (delegatees.length === 0) {
    logger.info('No delegatees found.');
    return;
  }

  logger.info('Current Delegatees:');
  delegatees.forEach((address) => {
    logger.log(`  - ${address}`);
  });
};
