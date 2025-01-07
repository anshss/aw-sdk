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
import { promptSelectPkp, promptSelectTool } from '../../prompts/delegatee';

// Import custom error types and utilities.
import { FssCliError, FssCliErrorType } from '../../errors';

/**
 * Handles the process of retrieving and displaying the policy for a selected tool registered under a specific PKP.
 * This function retrieves the list of delegated PKPs, prompts the user to select a PKP and a tool,
 * retrieves the tool's policy, decodes it, and logs the result. It also handles errors that occur during the process.
 *
 * @param fssDelegatee - An instance of the FssDelegatee class.
 */
export const handleGetToolPolicy = async (fssDelegatee: FssDelegatee) => {
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

    // Retrieve the list of registered tools for the selected PKP.
    const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
      selectedPkp.tokenId
    );

    // If no tools with policies are found, throw an error.
    if (registeredTools.toolsWithPolicies.length === 0) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_NO_TOOLS_WITH_POLICY,
        'No registered tools with a policy for this PKP.'
      );
    }

    // Filter tools with policies that match the current Lit network.
    const toolsWithPolicies: FssTool<any, any>[] = [];
    registeredTools.toolsWithPolicies.forEach((registeredTool) => {
      const registryTool = getToolByIpfsCid(registeredTool.ipfsCid);
      if (registryTool && registryTool.network === fssDelegatee.litNetwork) {
        toolsWithPolicies.push(registryTool.tool);
      }
    });

    // Prompt the user to select a tool.
    const selectedTool = await promptSelectTool(toolsWithPolicies, []);

    // Retrieve the tool details from the registry to decode the policy.
    const registryTool = getToolByIpfsCid(selectedTool.ipfsCid);
    if (!registryTool) {
      throw new Error(`Tool not found in registry: ${selectedTool.ipfsCid}`);
    }

    // Find the policy for the selected tool.
    const toolPolicy = registeredTools.toolsWithPolicies.find(
      (t) => t.ipfsCid === selectedTool.ipfsCid
    )?.policy;

    // If no policy is found, throw an error.
    if (!toolPolicy) {
      throw new FssCliError(
        FssCliErrorType.DELEGATEE_GET_TOOL_POLICY_TOOL_NOT_FOUND,
        'Selected tool not found'
      );
    }

    // Decode the policy.
    const decodedPolicy = registryTool.tool.policy.decode(toolPolicy);

    // Log the tool policy details.
    logger.info(
      `Tool Policy for PKP ${selectedPkp.tokenId} and Tool ${selectedTool.ipfsCid}:`
    );
    logger.log(`Version: ${selectedTool.policy.version}`);
    logger.log('Policy:');
    logger.log(JSON.stringify(decodedPolicy, null, 2));
  } catch (error) {
    // Handle specific errors related to tool policy retrieval.
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

    // Re-throw any other errors to be handled by the caller.
    throw error;
  }
};
