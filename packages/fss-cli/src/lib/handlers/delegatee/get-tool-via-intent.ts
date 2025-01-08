import {
  Delegatee as FssDelegatee,
  IntentMatcher,
  FssSignerError,
  FssSignerErrorType,
} from '@lit-protocol/fss-signer';

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
  try {
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
    const tool = await fssDelegatee.getToolViaIntent(
      selectedPkp.tokenId,
      intent,
      intentMatcher
    );

    if (tool.matchedTool === null) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_NO_MATCH,
        'No tool found for intent.'
      );
    }

    logger.success('Found matching tool:');
    logger.log(`  - ${tool.matchedTool.name} (${tool.matchedTool.ipfsCid})`);
    logger.log(`      - ${tool.matchedTool.description}`);

    return tool;
  } catch (error: unknown) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        logger.error('No PKP selected');
        return;
      }
      if (
        error.type === FssCliErrorType.DELEGATEE_GET_TOOL_VIA_INTENT_CANCELLED
      ) {
        logger.error('Intent input cancelled');
        return;
      }
      throw error;
    }

    if (error instanceof FssSignerError) {
      if (error.type === FssSignerErrorType.DELEGATEE_MISSING_CREDENTIALS) {
        logger.error('Missing required credentials for intent matcher');
        return;
      }
      throw error;
    }

    throw error;
  }
};
