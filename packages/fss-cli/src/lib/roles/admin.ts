import { Admin as FssAdmin } from '@lit-protocol/full-self-signing';
import { FssSignerError, FssSignerErrorType } from '@lit-protocol/fss-signer';

import { logger } from '../utils/logger';
import {
  promptAdminInit,
  promptAdminInsufficientBalance,
  promptAdminMenu,
} from '../prompts/admin';
import {
  handlePermitTool,
  handleRemoveTool,
  handleGetTools,
  handleGetToolPolicy,
  handleSetToolPolicy,
  handleRemoveToolPolicy,
  handleGetDelegatees,
  handleIsDelegatee,
  handleAddDelegatee,
  handleRemoveDelegatee,
  handleBatchAddDelegatee,
  handleBatchRemoveDelegatee,
} from '../handlers/admin';

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

  public static async showMenu(admin: Admin) {
    const option = await promptAdminMenu();

    switch (option) {
      case 'permitTool':
        await handlePermitTool(admin.fssAdmin);
        break;
      case 'removeTool':
        await handleRemoveTool(admin.fssAdmin);
        break;
      case 'getRegisteredTools':
        await handleGetTools(admin.fssAdmin);
        break;
      case 'getToolPolicy':
        await handleGetToolPolicy(admin.fssAdmin);
        break;
      case 'setToolPolicy':
        await handleSetToolPolicy(admin.fssAdmin);
        break;
      case 'removeToolPolicy':
        await handleRemoveToolPolicy(admin.fssAdmin);
        break;
      case 'getDelegatees':
        await handleGetDelegatees(admin.fssAdmin);
        break;
      case 'isDelegatee':
        await handleIsDelegatee(admin.fssAdmin);
        break;
      case 'addDelegatee':
        await handleAddDelegatee(admin.fssAdmin);
        break;
      case 'removeDelegatee':
        await handleRemoveDelegatee(admin.fssAdmin);
        break;
      case 'batchAddDelegatees':
        await handleBatchAddDelegatee(admin.fssAdmin);
        break;
      case 'batchRemoveDelegatees':
        await handleBatchRemoveDelegatee(admin.fssAdmin);
        break;
      default:
        logger.error('Invalid option selected');
        process.exit(1);
    }

    await Admin.showMenu(admin);
  }

  public disconnect() {
    this.fssAdmin.disconnect();
  }
}
