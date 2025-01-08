import {
  Delegatee as FssDelegatee,
  FssSignerError,
  FssSignerErrorType,
  IntentMatcher,
  LitNetwork,
} from '@lit-protocol/full-self-signing';

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
  handleExecuteTool,
} from '../handlers/delegatee';
import { handleGetIntentMatcher } from '../handlers/delegatee/get-intent-matcher';
import { handleGetToolViaIntent } from '../handlers/delegatee/get-tool-via-intent';
import { handleExecuteToolViaIntent } from '../handlers/delegatee/execute-tool-via-intent';

export class Delegatee {
  private fssDelegatee: FssDelegatee;

  public intentMatcher: IntentMatcher | null = null;

  private constructor(fssDelegatee: FssDelegatee) {
    this.fssDelegatee = fssDelegatee;
    logger.success('Delegatee role initialized successfully.');
  }

  private static async createFssDelegatee(
    litNetwork: LitNetwork,
    privateKey?: string
  ): Promise<FssDelegatee> {
    let fssDelegatee: FssDelegatee;
    try {
      fssDelegatee = await FssDelegatee.create(privateKey, { litNetwork });
    } catch (error) {
      if (error instanceof FssSignerError) {
        if (error.type === FssSignerErrorType.DELEGATEE_MISSING_PRIVATE_KEY) {
          const privateKey = await promptDelegateeInit();
          return Delegatee.createFssDelegatee(litNetwork, privateKey);
        }

        if (
          error.type ===
          FssSignerErrorType.INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT
        ) {
          const hasFunded = await promptDelegateeInsufficientBalance();
          if (hasFunded) {
            return Delegatee.createFssDelegatee(litNetwork, privateKey);
          }
        }
      }

      logger.error('Failed to initialize Delegatee role', error as Error);
      process.exit(1);
    }

    return fssDelegatee;
  }

  public static async create(
    litNetwork: LitNetwork,
    intentMatcher: IntentMatcher | null = null
  ) {
    logger.info('Initializing Delegatee role...');
    const fssDelegatee = await Delegatee.createFssDelegatee(litNetwork);
    const delegatee = new Delegatee(fssDelegatee);
    delegatee.intentMatcher = intentMatcher;
    return delegatee;
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
      case 'getToolViaIntent':
        if (delegatee.intentMatcher === null) {
          const intentMatcher = await handleGetIntentMatcher(
            delegatee.fssDelegatee
          );
          delegatee.setIntentMatcher(intentMatcher);
        }

        await handleGetToolViaIntent(
          delegatee.fssDelegatee,
          delegatee.intentMatcher as IntentMatcher
        );
        break;
      case 'executeToolViaIntent':
        if (delegatee.intentMatcher === null) {
          const intentMatcher = await handleGetIntentMatcher(
            delegatee.fssDelegatee
          );
          delegatee.setIntentMatcher(intentMatcher);
        }

        await handleExecuteToolViaIntent(
          delegatee.fssDelegatee,
          delegatee.intentMatcher as IntentMatcher
        );
        break;
      case 'executeTool':
        await handleExecuteTool(delegatee.fssDelegatee);
        break;
      default:
        logger.error('Invalid option selected');
        process.exit(1);
    }

    await Delegatee.showMenu(delegatee);
  }

  public setIntentMatcher(intentMatcher: IntentMatcher) {
    this.intentMatcher = intentMatcher;
  }

  public disconnect() {
    this.fssDelegatee.disconnect();
  }
}
