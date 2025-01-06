import prompts from 'prompts';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptDelegateeAddress = async () => {
  const { address } = await prompts({
    type: 'text',
    name: 'address',
    message: 'Enter the address to check:',
    validate: (value) => {
      if (!value) return 'Address is required';
      if (!/^0x[a-fA-F0-9]{40}$/.test(value)) return 'Invalid Ethereum address';
      return true;
    },
  });

  if (!address) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_CHECK_DELEGATEE_CANCELLED,
      'Delegatee check cancelled.'
    );
  }

  return address;
};
