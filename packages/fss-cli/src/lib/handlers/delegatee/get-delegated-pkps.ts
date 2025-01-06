import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

const getDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  logger.loading('Getting delegated PKPs...');
  return fssDelegatee.getDelegatedPkps();
};

export const handleGetDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  const pkps = await getDelegatedPkps(fssDelegatee);

  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return;
  }

  logger.info('PKPs Delegated to You:');
  pkps.forEach((pkpTokenId: string, i: number) => {
    logger.log(`  ${i + 1}. Token ID: ${pkpTokenId}`);
  });
};
