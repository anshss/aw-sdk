import {
  type FssTool,
  type Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';
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

    const toolsWithPolicies: FssTool<any, any>[] = [];
    registeredTools.toolsWithPolicies.forEach((registeredTool) => {
      const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);
      if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
        toolsWithPolicies.push(registryTool.tool);
      }
    });

    const selectedTool = await promptSelectTool(toolsWithPolicies, []);

    // Get the tool from the registry to decode the policy
    const registryTool = getToolByIpfsCid(selectedTool.ipfsCid);
    if (!registryTool) {
      throw new Error(`Tool not found in registry: ${selectedTool.ipfsCid}`);
    }

    // Decode the policy
    const toolPolicy = registeredTools.toolsWithPolicies.find(
      (t) => t.ipfsCid === selectedTool.ipfsCid
    )?.policy;

    if (!toolPolicy) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_TOOL_NOT_FOUND,
        'Selected tool not found'
      );
    }

    const decodedPolicy = registryTool.tool.policy.decode(toolPolicy);

    logger.info(
      `Tool Policy for PKP ${selectedPkp.tokenId} and Tool ${selectedTool.ipfsCid}:`
    );
    logger.log(`Version: ${selectedTool.policy.version}`);
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
