import { type Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';
import { type RegisteredTool } from '@lit-protocol/fss-signer';

import { logger } from '../../utils/logger';
import { promptSelectPkp } from '../../prompts/delegatee';
import { FssCliError, FssCliErrorType } from '../../errors';

const getRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  logger.loading('Getting registered tools...');

  // First get the PKPs delegated to this delegatee
  const pkps = await fssDelegatee.getDelegatedPkps();

  if (pkps.length === 0) {
    logger.error('No PKPs are currently delegated to you.');
    return;
  }

  // Prompt user to select a PKP
  const selectedPkp = await promptSelectPkp(pkps);

  // Get registered tools for the selected PKP
  const { toolsWithPolicies, toolsWithoutPolicies } =
    await fssDelegatee.getRegisteredToolsForPkp(selectedPkp.tokenId);

  return {
    pkpTokenId: selectedPkp,
    toolsWithPolicies,
    toolsWithoutPolicies,
  };
};

export const handleGetRegisteredTools = async (fssDelegatee: FssDelegatee) => {
  try {
    const result = await getRegisteredTools(fssDelegatee);
    if (result === undefined) return;

    const { pkpTokenId, toolsWithPolicies, toolsWithoutPolicies } = result;

    if (toolsWithPolicies.length === 0 && toolsWithoutPolicies.length === 0) {
      logger.info('No tools are registered for this PKP.');
      return;
    }

    logger.info(`Registered Tools for PKP ${pkpTokenId}:`);

    if (toolsWithPolicies.length > 0) {
      logger.info('Tools with Policies:');
      toolsWithPolicies.forEach((tool: RegisteredTool, i: number) => {
        logger.log(`  ${i + 1}. IPFS CID: ${tool.ipfsCid}`);
        logger.log(`     Version: ${tool.version}`);
      });
    }

    if (toolsWithoutPolicies.length > 0) {
      logger.info('Tools without Policies:');
      toolsWithoutPolicies.forEach((ipfsCid: string, i: number) => {
        logger.log(`  ${i + 1}. IPFS CID: ${ipfsCid}`);
      });
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
