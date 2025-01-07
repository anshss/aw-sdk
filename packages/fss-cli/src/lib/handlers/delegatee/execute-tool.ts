import {
  type FssTool,
  type Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';
import { getToolByIpfsCid } from '@lit-protocol/fss-tool-registry';

import { logger } from '../../utils/logger';
import {
  promptSelectPkp,
  promptSelectTool,
  promptToolParams,
} from '../../prompts/delegatee';
import { FssCliError, FssCliErrorType } from '../../errors';

export const handleExecuteTool = async (fssDelegatee: FssDelegatee) => {
  try {
    // Get PKP token IDs
    const pkps = await fssDelegatee.getDelegatedPkps();

    if (pkps.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_PKPS,
        'No PKPs are currently delegated to you.'
      );
    }

    const selectedPkp = await promptSelectPkp(pkps);

    const toolsWithPolicies: FssTool<any, any>[] = [];
    const toolsWithoutPolicies: FssTool<any, any>[] = [];

    const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkp.tokenId
    );

    if (registeredTools.toolsWithPolicies.length > 0) {
      logger.log(`Tools with Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithPolicies.forEach((registeredTool) => {
        const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);
        if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
          toolsWithPolicies.push(registryTool.tool);
          logger.log(
            `  - ${registryTool.tool.name} (${registeredTool.ipfsCid})`
          );
        }
      });
    }

    if (registeredTools.toolsWithoutPolicies.length > 0) {
      logger.log(`Tools without Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithoutPolicies.forEach((ipfsCid) => {
        const registryTool = getToolByIpfsCid(ipfsCid);
        if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
          toolsWithoutPolicies.push(registryTool.tool);
          logger.log(`  - ${registryTool.tool.name} (${ipfsCid})`);
        }
      });
    }

    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
        'No registered tools for this PKP.'
      );
    }

    // Select a tool
    const selectedTool = await promptSelectTool(
      toolsWithPolicies,
      toolsWithoutPolicies
    );

    // If the tool has a policy, display it
    const toolWithPolicy = toolsWithPolicies.find(
      (tool) => tool.ipfsCid === selectedTool.ipfsCid
    );
    if (toolWithPolicy) {
      const decodedPolicy = selectedTool.policy.decode(
        registeredTools.toolsWithPolicies.find(
          (t) => t.ipfsCid === selectedTool.ipfsCid
        )?.policy || ''
      );
      logger.info('Tool Policy:');
      logger.log(JSON.stringify(decodedPolicy, null, 2));
    }

    logger.info('Enter Tool Parameters:');
    const params = await promptToolParams(selectedTool, selectedPkp.ethAddress);

    // Execute the tool
    logger.loading('Executing tool...');

    const response = await fssDelegatee.executeTool({
      ipfsId: selectedTool.ipfsCid,
      jsParams: {
        params,
      },
    });
    logger.success('Tool executed successfully');

    console.log('response', response);
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
      if (
        error.type === FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED
      ) {
        logger.error('Tool parameter input cancelled');
        return;
      }
      if (
        error.type === FssCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID
      ) {
        logger.error(error.message);
        return;
      }
      if (
        error.type === FssCliErrorType.DELEGATEE_EXECUTE_TOOL_POLICY_VIOLATED
      ) {
        logger.error('Tool execution violates policy constraints');
        return;
      }
    }

    throw error;
  }
};
