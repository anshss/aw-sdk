import prompts from 'prompts';

import { AwCliError, AwCliErrorType } from '../../errors';

export const promptGetOpenAiApiKey = async (): Promise<string> => {
  const { apiKey } = await prompts({
    type: 'password',
    name: 'apiKey',
    message: 'Enter your OpenAI API key:',
  });

  if (!apiKey) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_GET_INTENT_MATCHER_CANCELLED,
      'OpenAI API key input cancelled'
    );
  }

  return apiKey;
};
