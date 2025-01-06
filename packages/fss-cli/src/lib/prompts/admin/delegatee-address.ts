import prompts from 'prompts';
import { ethers } from 'ethers';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptDelegateeAddress = async () => {
  const { address } = await prompts({
    type: 'text',
    name: 'address',
    message: 'Enter the delegatee address:',
    validate: (value) => {
      try {
        if (!value) return 'Address is required';
        ethers.utils.getAddress(value);
        return true;
      } catch {
        return 'Invalid Ethereum address';
      }
    },
  });

  if (!address) {
    throw new FssCliError(
      FssCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee operation cancelled.'
    );
  }

  return address;
};
