import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';


// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

// Import prompt utilities for user interaction.
import {
  promptSelectPkp,
  promptSelectTool,
  promptToolParams,
} from '../../prompts/delegatee';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

/**
 * Handles the process of executing a tool in the Full Self-Signing (FSS) system.
 * This function retrieves delegated PKPs, lists registered tools for the selected PKP,
 * prompts the user to select a tool and provide parameters, and executes the tool.
 * It also handles errors that occur during the process.
 *
 * @param fssDelegatee - An instance of the FssDelegatee class.
 */
export const handleExecuteTool = async (fssDelegatee: FssDelegatee) => {
  try {
    // Retrieve the list of PKPs delegated to the user.
    const pkps = await fssDelegatee.getDelegatedPkps();

    // If no PKPs are delegated, throw an error.
    if (pkps.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_PKPS,
        'No PKPs are currently delegated to you.'
      );
    }

    // Prompt the user to select a PKP.
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

    // Process tools without policies.
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

    // Prompt the user to provide tool parameters.
    logger.info('Enter Tool Parameters:');
    const params = await promptToolParams(selectedTool, selectedPkp.ethAddress);

    // Execute the tool.
    logger.loading('Executing tool...');
    const response = await fssDelegatee.executeTool({
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

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
