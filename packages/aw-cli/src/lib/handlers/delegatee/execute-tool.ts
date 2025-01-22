import type {
  DelegatedPkpInfo,
  Delegatee as AwDelegatee,
} from '@lit-protocol/agent-wallet';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import prompt utilities for user interaction.
import {
  promptSelectPkp,
  promptSelectTool,
  promptToolParams,
} from '../../prompts/delegatee';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Handles the process of executing a tool in the Full Self-Signing (AW) system.
 * This function retrieves delegated PKPs, lists registered tools for the selected PKP,
 * prompts the user to select a tool and provide parameters, and executes the tool.
 * It also handles errors that occur during the process.
 *
 * @param awDelegatee - An instance of the AwDelegatee class.
 */
export const handleExecuteTool = async (awDelegatee: AwDelegatee) => {
  try {
    // Retrieve the list of PKPs delegated to the user.
    const pkps = await awDelegatee.getDelegatedPkps();

    // If no PKPs are delegated, throw an error.
    if (pkps.length === 0) {
      throw new AwCliError(
        AwCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_PKPS,
        'No PKPs are currently delegated to you.'
      );
    }

    // Prompt the user to select a PKP.
    const selectedPkp = (await promptSelectPkp(pkps)) as DelegatedPkpInfo;

    const registeredTools = await awDelegatee.getPermittedToolsForPkp(
      selectedPkp.tokenId
    );

    if (
      Object.keys(registeredTools.toolsWithPolicies).length === 0 &&
      Object.keys(registeredTools.toolsWithoutPolicies).length === 0
    ) {
      throw new AwCliError(
        AwCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
        'No registered tools for this PKP.'
      );
    }

    if (Object.keys(registeredTools.toolsWithPolicies).length > 0) {
      logger.log(`Tools with Policies for PKP ${selectedPkp.ethAddress}:`);
      Object.entries(registeredTools.toolsWithPolicies).forEach(([ipfsCid, tool]) => {
        logger.log(`  - ${tool.name} (${ipfsCid})`);
      });
    }

    // Process tools without policies.
    if (Object.keys(registeredTools.toolsWithoutPolicies).length > 0) {
      logger.log(`Tools without Policies for PKP ${selectedPkp.ethAddress}:`);
      Object.entries(registeredTools.toolsWithoutPolicies).forEach(([ipfsCid, tool]) => {
        logger.log(`  - ${tool.name} (${ipfsCid})`);
      });
    }

    // Select a tool
    const selectedTool = await promptSelectTool(
      Object.entries(registeredTools.toolsWithPolicies).map(([ipfsCid, tool]) => ({
        ...tool,
        ipfsCid,
      })),
      Object.entries(registeredTools.toolsWithoutPolicies).map(([ipfsCid, tool]) => ({
        ...tool,
        ipfsCid,
      }))
    );

    // If the tool has a policy, display it
    const toolWithPolicy = Object.entries(registeredTools.toolsWithPolicies).find(
      ([ipfsCid]) => ipfsCid === selectedTool.ipfsCid
    );
    if (toolWithPolicy) {
      const policy = await awDelegatee.getToolPolicy(
        selectedPkp.tokenId,
        selectedTool.ipfsCid
      );
      const decodedPolicy = selectedTool.policy.decode(policy.policy);
      logger.info('Tool Policy:');
      logger.log(JSON.stringify(decodedPolicy, null, 2));
    }

    // Prompt the user to provide tool parameters.
    logger.info('Enter Tool Parameters:');
    const params = await promptToolParams(selectedTool, selectedPkp.ethAddress);

    // Execute the tool.
    logger.loading('Executing tool...');
    const response = await awDelegatee.executeTool({
      ipfsId: selectedTool.ipfsCid,
      jsParams: {
        params,
      },
    });

    // Log a success message once the tool is executed.
    logger.success('Tool executed successfully');

    // Log the execution response.
    console.log('response', response);
  } catch (error) {
    // Handle specific errors related to tool execution.
    if (error instanceof AwCliError) {
      if (error.type === AwCliErrorType.ADMIN_SELECT_PKP_CANCELLED) {
        logger.error('No PKP selected');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS) {
        logger.error('No tools available for the selected PKP');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_SELECT_TOOL_CANCELLED) {
        logger.error('No tool selected');
        return;
      }
      if (
        error.type === AwCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED
      ) {
        logger.error('Tool parameter input cancelled');
        return;
      }
      if (error.type === AwCliErrorType.DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID) {
        logger.error(error.message);
        return;
      }
      if (
        error.type === AwCliErrorType.DELEGATEE_EXECUTE_TOOL_POLICY_VIOLATED
      ) {
        logger.error('Tool execution violates policy constraints');
        return;
      }
    }

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
