import prompts from 'prompts';
import { type PkpInfo } from '@lit-protocol/agent-wallet';

import { logger } from '../../utils/logger';

/**
 * Prompts the user to confirm if they want to manage a specific PKP
 * @param pkp The PKP information to display
 * @returns boolean indicating whether the user wants to manage this PKP
 */
export const promptManagePkp = async (pkp: PkpInfo) => {
  const { confirmed } = await prompts({
    type: 'confirm',
    name: 'confirmed',
    message: `Would you like to manage the Agent Wallet: ${pkp.info.ethAddress}?`,
    initial: true,
  });

  if (confirmed === undefined) {
    logger.error('No selection made');
    process.exit(1);
  }

  return confirmed;
};
