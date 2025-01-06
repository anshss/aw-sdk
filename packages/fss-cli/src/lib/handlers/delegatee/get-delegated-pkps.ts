import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { FssCliError, FssCliErrorType } from '../../errors';

const getDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  logger.loading('Getting delegated PKPs...');
  const pkps = await fssDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_GET_DELEGATED_PKPS_NO_PKPS,
      'No PKPs delegated to delegatee'
    );
  }

  return pkps;
};

export const handleGetDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  try {
    const pkps = await getDelegatedPkps(fssDelegatee);

    logger.info('PKPs Delegated to You:');
    pkps.forEach((pkpTokenId: string, i: number) => {
      logger.log(`  ${i + 1}. Token ID: ${pkpTokenId}`);
    });
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_GET_DELEGATED_PKPS_NO_PKPS) {
        logger.error('No PKPs are currently delegated to you.');
        return;
      }
    }

    throw error;
  }
};
