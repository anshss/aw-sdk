import type { Admin as AwAdmin, PkpInfo } from '@lit-protocol/agent-wallet';

import { promptNewPkpOwner } from '../../prompts/admin';
import { AwCliErrorType, AwCliError } from '../../errors';
import { logger } from '../../utils/logger';

export const handleTransferOwnership = async (
  awAdmin: AwAdmin,
  pkp: PkpInfo
) => {
  const newOwner = await promptNewPkpOwner(pkp.info.ethAddress);

  if (!newOwner) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_PKP_OWNERSHIP_TRANSFER_CANCELLED,
      'Transfer ownership cancelled'
    );
  }

  const receipt = await awAdmin.transferPkpOwnership(
    pkp.info.tokenId,
    newOwner
  );

  logger.success(`PKP ownership transferred to ${newOwner} successfully`);
  logger.info(
    `Block explorer URL: https://yellowstone-explorer.litprotocol.com/tx/${receipt.transactionHash}`
  );
};
