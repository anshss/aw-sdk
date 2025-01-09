import prompts from 'prompts';

import { AwCliError, AwCliErrorType } from '../../errors';

export const promptToolMatchingIntent = async (): Promise<string> => {
  const { intent } = await prompts({
    type: 'text',
    name: 'intent',
    message: 'What would you like to do?',
  });

  if (!intent) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_GET_TOOL_MATCHING_INTENT_CANCELLED,
      'Intent input cancelled'
    );
  }

  return intent;
};
