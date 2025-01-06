import prompts from 'prompts';

import { logger } from '../../utils/logger';

export const promptDelegateeInit = async () => {
  const privateKeyResponse = await prompts({
    type: 'password',
    name: 'privateKey',
    message: 'Enter your private key:',
  });

  if (!privateKeyResponse.privateKey) {
    logger.error('Private key is required to proceed.');
    process.exit(1);
  }

  return privateKeyResponse.privateKey;
};
