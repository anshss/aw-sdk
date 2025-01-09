import {
  Delegatee as AwDelegatee,
  OpenAiIntentMatcher,
} from '@lit-protocol/agent-wallet';

import { promptGetOpenAiApiKey } from '../../prompts/delegatee/open-ai-api-key';

export const handleGetIntentMatcher = async (
  awDelegatee: AwDelegatee
): Promise<OpenAiIntentMatcher> => {
  const { foundCredentials, missingCredentials } =
    await awDelegatee.getCredentials<typeof OpenAiIntentMatcher>(
      OpenAiIntentMatcher.requiredCredentialNames
    );

  // TODO This shouldn't assume that the OpenAI API key is the only credential
  if (missingCredentials.length > 0) {
    const apiKey = await promptGetOpenAiApiKey();
    await awDelegatee.setCredentials<typeof OpenAiIntentMatcher>({
      openAiApiKey: apiKey,
    });
    return new OpenAiIntentMatcher(apiKey);
  }

  return new OpenAiIntentMatcher(foundCredentials.openAiApiKey!);
};
