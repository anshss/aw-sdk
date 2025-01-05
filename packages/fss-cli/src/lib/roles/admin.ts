import { Admin as FssAdmin } from '@lit-protocol/full-self-signing';
import { FssSignerError, FssSignerErrorType } from '@lit-protocol/fss-signer';

import { logger } from '../utils/logger';
import { promptAdminInit } from '../prompts/admin/init';
import { promptAdminInsufficientBalance } from '../prompts/admin/insuffcient-balance';

export class Admin {
  private static async createFssAdmin(privateKey: string): Promise<FssAdmin> {
    let fssAdmin: FssAdmin;
    try {
      fssAdmin = await FssAdmin.create({
        type: 'eoa',
        privateKey,
      });
    } catch (error) {
      if (error instanceof FssSignerError) {
        if (error.type === FssSignerErrorType.INSUFFICIENT_BALANCE_PKP_MINT) {
          const hasFunded = await promptAdminInsufficientBalance();
          if (hasFunded) {
            return Admin.createFssAdmin(privateKey);
          }
        }
      }

      logger.error('Failed to initialize Admin role', error as Error);
      process.exit(1);
    }

    return fssAdmin;
  }

  public static async create() {
    logger.info('Initializing Admin role...');

    const privateKey = await promptAdminInit();
    const fssAdmin = await Admin.createFssAdmin(privateKey);
    console.log(fssAdmin);

    logger.success('Admin role initialized successfully.');
  }
}
