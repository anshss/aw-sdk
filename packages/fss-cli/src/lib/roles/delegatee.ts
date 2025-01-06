import { Delegatee as FssDelegatee } from '@lit-protocol/full-self-signing';
import { FssSignerError, FssSignerErrorType } from '@lit-protocol/fss-signer';

import { logger } from '../utils/logger';
import {
  promptDelegateeInit,
  promptDelegateeInsufficientBalance,
  promptDelegateeMenu,
} from '../prompts/delegatee';
import {
  handleGetDelegatedPkps,
  handleGetRegisteredTools,
  handleGetToolPolicy,
} from '../handlers/delegatee';

export class Delegatee {
  private fssDelegatee: FssDelegatee;

  private constructor(fssDelegatee: FssDelegatee) {
    this.fssDelegatee = fssDelegatee;
    logger.success('Delegatee role initialized successfully.');
  }

  private static async createFssDelegatee(
    privateKey?: string
  ): Promise<FssDelegatee> {
    let fssDelegatee: FssDelegatee;
    try {
      fssDelegatee = await FssDelegatee.create(privateKey);
    } catch (error) {
      if (error instanceof FssSignerError) {
        if (error.type === FssSignerErrorType.DELEGATEE_MISSING_PRIVATE_KEY) {
          const privateKey = await promptDelegateeInit();
          return Delegatee.createFssDelegatee(privateKey);
        }

        if (
          error.type ===
          FssSignerErrorType.INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT
        ) {
          const hasFunded = await promptDelegateeInsufficientBalance();
          if (hasFunded) {
            return Delegatee.createFssDelegatee(privateKey);
          }
        }
      }

      logger.error('Failed to initialize Delegatee role', error as Error);
      process.exit(1);
    }

    return fssDelegatee;
  }

  public static async create() {
    logger.info('Initializing Delegatee role...');
    const fssDelegatee = await Delegatee.createFssDelegatee();
    return new Delegatee(fssDelegatee);
  }

  public static async showMenu(delegatee: Delegatee) {
    const option = await promptDelegateeMenu();

    switch (option) {
      case 'getDelegatedPkps':
        await handleGetDelegatedPkps(delegatee.fssDelegatee);
        break;
      case 'getRegisteredTools':
        await handleGetRegisteredTools(delegatee.fssDelegatee);
        break;
      case 'getToolPolicy':
        await handleGetToolPolicy(delegatee.fssDelegatee);
        break;
      case 'executeTool':
        // await handleExecuteTool(delegatee.fssDelegatee);
        break;
      default:
        logger.error('Invalid option selected');
        process.exit(1);
    }

    await Delegatee.showMenu(delegatee);
  }

  public disconnect() {
    this.fssDelegatee.disconnect();
  }
}
