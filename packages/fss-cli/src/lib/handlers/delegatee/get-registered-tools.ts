import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';

import { logger } from '../../utils/logger';
import { promptSelectPkp } from '../../prompts/delegatee';
import { FssCliError, FssCliErrorType } from '../../errors';

const getRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  logger.loading('Getting registered tools...');

  // First get the PKPs delegated to this delegatee
  const pkps = await fssDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return null;
  }

  // Prompt user to select a PKP
  const selectedPkp = await promptSelectPkp(pkps);

  const registeredTools = await fssDelegatee.getRegisteredToolsForPkp(
    selectedPkp.tokenId
  );

  if (registeredTools.toolsWithPolicies.length > 0) {
    logger.log(`Tools with Policies:`);
    registeredTools.toolsWithPolicies.forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (registeredTools.toolsWithoutPolicies.length > 0) {
    logger.log(`Tools without Policies:`);
    registeredTools.toolsWithoutPolicies.forEach((tool) => {
      logger.log(`  - ${tool.name} (${tool.ipfsCid})`);
      logger.log(`      - ${tool.description}`);
    });
  }

  if (registeredTools.toolsUnknownWithPolicies.length > 0) {
    logger.log(`Unknown Tools with Policies:`);
    registeredTools.toolsUnknownWithPolicies.forEach((tool) => {
      logger.log(`  - Unknown tool: ${tool.ipfsCid}`);
    });
  }

  if (registeredTools.toolsUnknownWithoutPolicies.length > 0) {
    logger.log(`Unknown Tools without Policies:`);
    registeredTools.toolsUnknownWithoutPolicies.forEach((ipfsCid) => {
      logger.log(`  - Unknown tool: ${ipfsCid}`);
    });
  }

  return {
    pkpInfo: selectedPkp,
    toolsWithPolicies: registeredTools.toolsWithPolicies,
    toolsWithoutPolicies: registeredTools.toolsWithoutPolicies,
  };
};

export const handleGetRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  try {
    const result = await getRegisteredTools(fssDelegatee);
    if (result === null) return;

    const { toolsWithPolicies, toolsWithoutPolicies } = result;

    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      logger.info('No tools are registered for this PKP.');
      return;
    }
  } catch (error) {
    if (error instanceof FssCliError) {
      if (error.type === FssCliErrorType.DELEGATEE_SELECT_PKP_CANCELLED) {
        logger.error('No PKP selected');
        return;
      }
    }

    throw error;
  }
};
