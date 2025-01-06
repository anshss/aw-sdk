import prompts from 'prompts';

import { logger } from '../../utils/logger';

export const promptDelegateeInsufficientBalance = async () => {
  logger.error(
    'Insufficient Lit test token balance to mint Lit Capacity Credit.'
  );

  logger.info(
    'Please fund your wallet with Lit test tokens from: https://chronicle-yellowstone-faucet.getlit.dev/'
  );

  const fundingResponse = await prompts({
    type: 'confirm',
    name: 'hasFunded',
    message: 'Have you funded your Delegatee wallet with Lit test tokens?',
    initial: false,
  });

  if (fundingResponse.hasFunded) {
    return true;
  }

  logger.error(
    'Lit test tokens are required for minting PKPs and registering policies. Please fund your wallet and try again.'
  );
  return false;
};
