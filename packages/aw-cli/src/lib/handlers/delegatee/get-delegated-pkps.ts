// Import the DelegatedPkpInfo and FssDelegatee types from the '@lit-protocol/full-self-signing' package.
import type {
  DelegatedPkpInfo,
  Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Retrieves and displays the list of PKPs (Programmable Key Pairs) delegated to the user.
 * This function logs the progress of the operation and handles cases where no PKPs are delegated.
 *
 * @param fssDelegatee - An instance of the FssDelegatee class.
 */
export const handleGetDelegatedPkps = async (fssDelegatee: FssDelegatee) => {
  // Log a loading message to indicate the operation is in progress.
  logger.loading('Getting delegated PKPs...');

  // Retrieve the list of PKPs delegated to the user.
  const pkps = await fssDelegatee.getDelegatedPkps();

  // If no PKPs are delegated, log an error message and exit.
  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return;
  }

  // Log the list of delegated PKPs.
  logger.info('PKPs Delegated to You:');
  pkps.forEach((pkp: DelegatedPkpInfo, i: number) => {
    logger.log(`  ${i + 1}. Ethereum Address: ${pkp.ethAddress}`);
    logger.log(`    - Public Key: ${pkp.publicKey}`);
    logger.log(`    - Token ID: ${pkp.tokenId}`);
  });
};
