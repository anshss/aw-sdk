import type {
  DelegatedPkpInfo,
  Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';

export const handleGetDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  logger.loading('Getting delegated PKPs...');
  const pkps = await fssDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return;
  }

  logger.info('PKPs Delegated to You:');
  pkps.forEach((pkp: DelegatedPkpInfo, i: number) => {
    logger.log(`  ${i + 1}. Token ID: ${pkp.tokenId}`);
  });
};
