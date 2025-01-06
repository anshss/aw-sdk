import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';
import { getToolByIpfsCid } from '@lit-protocol/fss-tool-registry';

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

    const selectedPkpTokenId = await promptSelectPkp(pkps);

    const { toolsWithPolicies } = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkpTokenId
    );

    if (toolsWithPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_TOOLS_WITH_POLICY,
        'No registered tools with a policy for this PKP.'
      );
    }

    const { ipfsCid: selectedToolIpfsCid } = await promptSelectTool(
      toolsWithPolicies,
      []
    );

    const selectedTool = toolsWithPolicies.find(
      (tool) => tool.ipfsCid === selectedToolIpfsCid
    );

    if (!selectedTool) {
      throw new Error('Selected tool not found');
    }

    // Get the tool from the registry to decode the policy
    const registryTool = getToolByIpfsCid(selectedToolIpfsCid);
    if (!registryTool) {
      throw new Error(`Tool not found in registry: ${selectedToolIpfsCid}`);
    }

    // Decode the policy
    const decodedPolicy = registryTool.policy.decode(selectedTool.policy);

    logger.info(
      `Tool Policy for PKP ${selectedPkpTokenId} and Tool ${selectedTool.ipfsCid}:`
    );
    logger.log(`Version: ${selectedTool.version}`);
    logger.log('Policy:');
    logger.log(JSON.stringify(decodedPolicy, null, 2));
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        logger.error('No PKP selected');
        return;
      }
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS) {
        logger.error('No tools available for the selected PKP');
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
