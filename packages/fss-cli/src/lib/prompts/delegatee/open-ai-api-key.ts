import prompts from 'prompts';

import { FssCliError, FssCliErrorType } from '../../errors';

export const promptGetOpenAiApiKey = async (): Promise<string> => {
  const { apiKey } = await prompts({
    type: 'password',
    name: 'apiKey',
    message: 'Enter your OpenAI API key:',
  });

  if (!apiKey) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_GET_INTENT_MATCHER_CANCELLED,
      'OpenAI API key input cancelled'
    );
  }

  return apiKey;
};
