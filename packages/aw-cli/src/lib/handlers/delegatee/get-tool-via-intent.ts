import {
  Delegatee as AwDelegatee,
  IntentMatcher,
} from '@lit-protocol/agent-wallet';

import { logger } from '../../utils/logger';
import {
  promptSelectPkp,
  promptToolMatchingIntent,
} from '../../prompts/delegatee';
import { AwCliError, AwCliErrorType } from '../../errors';

export const handleGetToolViaIntent = async (
  awDelegatee: AwDelegatee,
  intentMatcher: IntentMatcher
) => {
  const pkps = await awDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_NO_TOOLS,
      'No PKPs are currently delegated to you.'
    );
  }

  const selectedPkp = await promptSelectPkp(pkps);
  const intent = await promptToolMatchingIntent();

  logger.loading('Finding tool for intent...');
  const intentMatcherResponse = await awDelegatee.getToolViaIntent(
    selectedPkp.tokenId,
    intent,
    intentMatcher
  );

  if (intentMatcherResponse.matchedTool === null) {
    throw new AwCliError(
      AwCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_NO_MATCH,
      `No tool found for intent, Lit sub agent reasoning: ${intentMatcherResponse.analysis.reasoning}`
    );
  }

  logger.success('Found matching tool:');
  logger.log(
    `  - ${intentMatcherResponse.matchedTool.name} (${intentMatcherResponse.matchedTool.ipfsCid})`
  );
  logger.log(`      - ${intentMatcherResponse.matchedTool.description}`);
  logger.log(
    `      - Lit sub agent reasoning: ${intentMatcherResponse.analysis.reasoning}`
  );
  return {
    selectedPkp,
    intentMatcherResponse,
  };
};
