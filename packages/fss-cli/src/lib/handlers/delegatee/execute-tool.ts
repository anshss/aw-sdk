import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';

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

    const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkp.tokenId
    );

    if (
      registeredTools.toolsWithPolicies.length === 0 &&
      registeredTools.toolsWithoutPolicies.length === 0
    ) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
        'No registered tools for this PKP.'
      );
    }

    if (registeredTools.toolsWithPolicies.length > 0) {
      logger.log(`Tools with Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithPolicies.forEach((tool) => {
        logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      });
    }

    if (registeredTools.toolsWithoutPolicies.length > 0) {
      logger.log(`Tools without Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithoutPolicies.forEach((tool) => {
        logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      });
    }

    // Select a tool
    const selectedTool = await promptSelectTool(
      registeredTools.toolsWithPolicies,
      registeredTools.toolsWithoutPolicies
    );

    // If the tool has a policy, display it
    const toolWithPolicy = registeredTools.toolsWithPolicies.find(
      (tool) => tool.ipfsCid === selectedTool.ipfsCid
    );
    if (toolWithPolicy) {
      const policy = await fssDelegatee.getToolPolicy(
        selectedPkp.tokenId,
        selectedTool.ipfsCid
      );
      const decodedPolicy = selectedTool.policy.decode(policy.policy);
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
