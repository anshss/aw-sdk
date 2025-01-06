import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';
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

    // Get registered tools
    const { toolsWithPolicies, toolsWithoutPolicies } =
      await fssDelegatee.getRegisteredToolsForPkp(selectedPkp.tokenId);

    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
        'No registered tools for this PKP.'
      );
    }

    // Select a tool
    const { ipfsCid: selectedToolIpfsCid } = await promptSelectTool(
      toolsWithPolicies,
      toolsWithoutPolicies
    );

    // Find the selected tool's policy if it exists
    const selectedTool = toolsWithPolicies.find(
      (tool) => tool.ipfsCid === selectedToolIpfsCid
    );

    // Get the tool from the registry
    const registryTool = getToolByIpfsCid(selectedToolIpfsCid);
    if (!registryTool) {
      throw new Error(`Tool not found in registry: ${selectedToolIpfsCid}`);
    }

    // If the tool has a policy, display it
    if (selectedTool) {
      const decodedPolicy = registryTool.policy.decode(selectedTool.policy);
      logger.info('\nTool Policy:');
      logger.log(JSON.stringify(decodedPolicy, null, 2));
    }

    // Get parameters from user
    logger.info('\nEnter Tool Parameters:');
    const params = await promptToolParams(registryTool);

    // Execute the tool
    logger.loading('Executing tool...');

    console.log('executeTool params', {
      ipfsId: selectedToolIpfsCid,
      jsParams: {
        pkp: { ...selectedPkp },
        params,
      },
    });

    // await fssDelegatee.executeTool({
    //   ipfsId: selectedToolIpfsCid,
    //   jsParams: {
    //     ...params,
    //     pkpTokenId: selectedPkpTokenId,
    //   },
    // });
    logger.success('Tool executed successfully');
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
