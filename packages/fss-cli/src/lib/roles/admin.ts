import { Admin as FssAdmin } from '@lit-protocol/full-self-signing';
import { FssSignerError, FssSignerErrorType } from '@lit-protocol/fss-signer';
import prompts from 'prompts';

import { logger } from '../utils/logger';
import { promptAdminInit } from '../prompts/admin/init';
import { promptAdminInsufficientBalance } from '../prompts/admin/insuffcient-balance';

export class Admin {
  private fssAdmin: FssAdmin;

  private constructor(fssAdmin: FssAdmin) {
    this.fssAdmin = fssAdmin;

    logger.success('Admin role initialized successfully.');
  }

  private static async createFssAdmin(privateKey?: string): Promise<FssAdmin> {
    let fssAdmin: FssAdmin;
    try {
      fssAdmin = await FssAdmin.create({
        type: 'eoa',
        privateKey,
      });
    } catch (error) {
      if (error instanceof FssSignerError) {
        if (error.type === FssSignerErrorType.ADMIN_MISSING_PRIVATE_KEY) {
          const privateKey = await promptAdminInit();
          return Admin.createFssAdmin(privateKey);
        }

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
    const fssAdmin = await Admin.createFssAdmin();
    return new Admin(fssAdmin);
  }

  public static async showMenu() {
    const { option } = await prompts({
      type: 'select',
      name: 'option',
      message: 'Select an action:',
      choices: [
        { title: 'Permit Tool', value: 'permitTool' },
        { title: 'Remove Tool', value: 'removeTool' },
        { title: 'Get Registered Tools', value: 'getRegisteredTools' },
        { title: 'Get Tool Policy', value: 'getToolPolicy' },
        { title: 'Set Tool Policy', value: 'setToolPolicy' },
        { title: 'Remove Tool Policy', value: 'removeToolPolicy' },
        { title: 'Get Delegatees', value: 'getDelegatees' },
        { title: 'Check if Address is Delegatee', value: 'isDelegatee' },
        { title: 'Add Delegatee', value: 'addDelegatee' },
        { title: 'Remove Delegatee', value: 'removeDelegatee' },
        { title: 'Batch Add Delegatees', value: 'batchAddDelegatees' },
        { title: 'Batch Remove Delegatees', value: 'batchRemoveDelegatees' },
      ],
    });

    if (!option) {
      logger.error('No option selected');
      process.exit(1);
    }

    switch (option) {
      case 'permitTool':
        logger.info('Executing: Permit Tool');
        break;
      case 'removeTool':
        logger.info('Executing: Remove Tool');
        break;
      case 'getRegisteredTools':
        logger.info('Executing: Get Registered Tools');
        break;
      case 'getToolPolicy':
        logger.info('Executing: Get Tool Policy');
        break;
      case 'setToolPolicy':
        logger.info('Executing: Set Tool Policy');
        break;
      case 'removeToolPolicy':
        logger.info('Executing: Remove Tool Policy');
        break;
      case 'getDelegatees':
        logger.info('Executing: Get Delegatees');
        break;
      case 'isDelegatee':
        logger.info('Executing: Check if Address is Delegatee');
        break;
      case 'addDelegatee':
        logger.info('Executing: Add Delegatee');
        break;
      case 'removeDelegatee':
        logger.info('Executing: Remove Delegatee');
        break;
      case 'batchAddDelegatees':
        logger.info('Executing: Batch Add Delegatees');
        break;
      case 'batchRemoveDelegatees':
        logger.info('Executing: Batch Remove Delegatees');
        break;
      default:
        logger.error('Invalid option selected');
        process.exit(1);
    }
  }

  public async disconnect() {
    this.fssAdmin.disconnect();
  }
}
