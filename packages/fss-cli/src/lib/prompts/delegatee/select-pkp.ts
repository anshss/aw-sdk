import prompts from 'prompts';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptSelectPkp = async (pkps: string[]) => {
  const { pkpTokenId } = await prompts({
    type: 'select',
    name: 'pkpTokenId',
    message: 'Select a PKP:',
    choices: pkps.map((pkp, i) => ({
      title: `${i + 1}: ${pkp}`,
      value: pkp,
    })),
  });

  if (!pkpTokenId) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED,
      'No PKP selected'
    );
  }

  return pkpTokenId;
};
