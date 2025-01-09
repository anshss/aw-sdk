import {
  Delegatee as AwDelegatee,
  IntentMatcher,
} from '@lit-protocol/agent-wallet';

import { logger } from '../../utils/logger';
import { handleGetToolViaIntent } from './get-tool-via-intent';
import { promptToolParams } from '../../prompts/delegatee';

export const handleExecuteToolViaIntent = async (
  awDelegatee: AwDelegatee,
  intentMatcher: IntentMatcher
) => {
  const { selectedPkp, intentMatcherResponse } = await handleGetToolViaIntent(
    awDelegatee,
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

  const response = await awDelegatee.executeTool({
    ipfsId: intentMatcherResponse.matchedTool!.ipfsCid,
    jsParams: {
      params,
    },
  });
  logger.success('Tool executed successfully');

  console.log('response', response);
};
