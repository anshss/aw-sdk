import prompts from 'prompts';
import { type DelegatedPkpInfo } from '@lit-protocol/full-self-signing';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectPkp = async (pkps: DelegatedPkpInfo[]) => {
  const selectedPkp = await prompts({
    type: 'select',
    name: 'pkp',
    message: 'Select a PKP:',
    choices: pkps.map((pkp, i) => ({
      title: `${i + 1}: ${pkp.ethAddress} (${pkp.tokenId})`,
      value: pkp,
    })),
  });

  if (!selectedPkp.pkp) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED,
      'No PKP selected'
    );
  }

  return selectedPkp.pkp as DelegatedPkpInfo;
};
