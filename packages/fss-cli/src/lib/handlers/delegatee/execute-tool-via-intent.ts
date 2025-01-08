import {
  Delegatee as FssDelegatee,
  IntentMatcher,
} from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { handleGetToolViaIntent } from './get-tool-via-intent';
import { promptToolParams } from '../../prompts/delegatee';

export const handleExecuteToolViaIntent = async (
  fssDelegatee: FssDelegatee,
  intentMatcher: IntentMatcher
) => {
  const { selectedPkp, intentMatcherResponse } = await handleGetToolViaIntent(
    fssDelegatee,
    intentMatcher
  );

  const params = await promptToolParams(
    intentMatcherResponse.matchedTool!,
    selectedPkp.ethAddress,
    {
      missingParams: intentMatcherResponse.params.missingParams,
      foundParams: intentMatcherResponse.params.foundParams,
    }
  );

  logger.loading('Executing tool...');

  const response = await fssDelegatee.executeTool({
    ipfsId: intentMatcherResponse.matchedTool!.ipfsCid,
    jsParams: {
      params,
    },
  });
  logger.success('Tool executed successfully');

  console.log('response', response);
};
