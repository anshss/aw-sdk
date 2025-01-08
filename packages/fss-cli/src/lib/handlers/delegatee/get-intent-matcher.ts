import {
  Delegatee as FssDelegatee,
  OpenAiIntentMatcher,
} from '@lit-protocol/full-self-signing';

import { promptGetOpenAiApiKey } from '../../prompts/delegatee/open-ai-api-key';

export const handleGetIntentMatcher = async (
  fssDelegatee: FssDelegatee
): Promise<OpenAiIntentMatcher> => {
  const { foundCredentials, missingCredentials } =
    await fssDelegatee.getCredentials<typeof OpenAiIntentMatcher>(
      OpenAiIntentMatcher.requiredCredentialNames
    );

  // TODO This shouldn't assume that the OpenAI API key is the only credential
  if (missingCredentials.length > 0) {
    const apiKey = await promptGetOpenAiApiKey();
    await fssDelegatee.setCredentials<typeof OpenAiIntentMatcher>({
      openai_api_key: apiKey,
    });
    return new OpenAiIntentMatcher(apiKey);
  }

  return new OpenAiIntentMatcher(foundCredentials.openai_api_key!);
};
