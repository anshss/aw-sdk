// Import the FssTool and FssDelegatee types from the '@lit-protocol/full-self-signing' package.
import {
  type FssTool,
  type Delegatee as FssDelegatee,
} from '@lit-protocol/full-self-signing';

// Import the getToolByIpfsCid function to retrieve tool details from the registry.
import { getToolByIpfsCid } from '@lit-protocol/fss-tool-registry';

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

    // Initialize arrays to store tools with and without policies.
    const toolsWithPolicies: FssTool<any, any>[] = [];
    const toolsWithoutPolicies: FssTool<any, any>[] = [];

    // Retrieve the list of registered tools for the selected PKP.
    const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkp.tokenId
    );

    // Process tools with policies.
    if (registeredTools.toolsWithPolicies.length > 0) {
      logger.log(`Tools with Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithPolicies.forEach((registeredTool) => {
        // Retrieve the tool details from the registry using its IPFS CID.
        const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);

        // If the tool is found and matches the current Lit network, add it to the list.
        if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
          toolsWithPolicies.push(registryTool.tool);
          logger.log(
            `  - ${registryTool.tool.name} (${registeredTool.ipfsCid})`
          );
        }
      });
    }

    // Process tools without policies.
    if (registeredTools.toolsWithoutPolicies.length > 0) {
      logger.log(`Tools without Policies for PKP ${selectedPkp.ethAddress}:`);
      registeredTools.toolsWithoutPolicies.forEach((ipfsCid) => {
        // Retrieve the tool details from the registry using its IPFS CID.
        const registryTool = getToolByIpfsCid(ipfsCid);

        // If the tool is found and matches the current Lit network, add it to the list.
        if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
          toolsWithoutPolicies.push(registryTool.tool);
          logger.log(`  - ${registryTool.tool.name} (${ipfsCid})`);
        }
      });
    }

    // If no tools are found for the selected PKP, throw an error.
    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_SELECT_TOOL_NO_TOOLS,
        'No registered tools for this PKP.'
      );
    }

    // Prompt the user to select a tool.
    const selectedTool = await promptSelectTool(
      toolsWithPolicies,
      toolsWithoutPolicies
    );

    // If the selected tool has a policy, display it.
    const toolWithPolicy = toolsWithPolicies.find(
      (tool) => tool.ipfsCid === selectedTool.ipfsCid
    );
    if (toolWithPolicy) {
      // Decode and log the tool's policy.
      const decodedPolicy = selectedTool.policy.decode(
        registeredTools.toolsWithPolicies.find(
          (t) => t.ipfsCid === selectedTool.ipfsCid
        )?.policy || ''
      );
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
