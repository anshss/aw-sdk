import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { promptSelectPkp, promptSelectTool } from '../../prompts/delegatee';
import { FssCliError, FssCliErrorType } from '../../errors';

export const handleGetToolPolicy = async (fssDelegatee: FssDelegatee) => {
  try {
    // PKP token IDs
    const pkps = await fssDelegatee.getDelegatedPkps();

    if (pkps.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_PKPS,
        'No PKPs are currently delegated to you.'
      );
    }

    const selectedPkp = await promptSelectPkp(pkps);

    const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkp.tokenId
    );

    if (registeredTools.toolsWithPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_TOOLS_WITH_POLICY,
        'No registered tools with a policy for this PKP.'
      );
    }

    const selectedTool = await promptSelectTool(
      registeredTools.toolsWithPolicies,
      []
    );

    const policy = await fssDelegatee.getToolPolicy(
      selectedPkp.tokenId,
      selectedTool.ipfsCid
    );

    const decodedPolicy = selectedTool.policy.decode(policy.policy);

    logger.info(
      `Tool Policy for PKP ${selectedPkp.tokenId} and Tool ${selectedTool.ipfsCid}:`
    );
    logger.log(`Version: ${policy.version}`);
    logger.log('Policy:');
    logger.log(JSON.stringify(decodedPolicy, null, 2));
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        logger.error('No PKP selected');
        return;
      }
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS) {
        logger.error(
          'No known tools with policies available for the selected PKP'
        );
        return;
      }
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_TOOL_CANCELLED) {
        logger.error('No tool selected');
        return;
      }
      if (error.type === FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_POLICY) {
        logger.error(error.message);
        return;
      }
    }

    throw error;
  }
};
