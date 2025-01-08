import {
  Delegatee as FssDelegatee,
  IntentMatcher,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import {
  promptSelectPkp,
  promptToolMatchingIntent,
} from '../../prompts/delegatee';
import { FssCliError, FssCliErrorType } from '../../errors';

export const handleGetToolViaIntent = async (
  fssDelegatee: FssDelegatee,
  intentMatcher: IntentMatcher
) => {
  const pkps = await fssDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_NO_TOOLS,
      'No PKPs are currently delegated to you.'
    );
  }

  const selectedPkp = await promptSelectPkp(pkps);
  const intent = await promptToolMatchingIntent();

  logger.loading('Finding tool for intent...');
  const intentMatcherResponse = await fssDelegatee.getToolViaIntent(
    selectedPkp.tokenId,
    intent,
    intentMatcher
  );

  if (intentMatcherResponse.matchedTool === null) {
    throw new FssCliError(
      FssCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_NO_MATCH,
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
