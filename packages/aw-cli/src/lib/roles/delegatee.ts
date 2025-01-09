import {
  Delegatee as AwDelegatee,
  AwSignerError,
  AwSignerErrorType,
  IntentMatcher,
  LitNetwork,
} from '@lit-protocol/agent-wallet';

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

/**
 * The `Delegatee` class is responsible for managing the Delegatee role in the Lit Protocol.
 * It initializes the Delegatee role, handles user interactions via a menu, and delegates actions to appropriate handlers.
 */
export class Delegatee {
  // Private instance of the AwDelegatee class.
  private awDelegatee: AwDelegatee;

  public intentMatcher: IntentMatcher | null = null;
  /**
   * Private constructor for the Delegatee class.
   * @param awDelegatee - An instance of the `AwDelegatee` class.
   */
  private constructor(awDelegatee: AwDelegatee) {
    this.awDelegatee = awDelegatee;
    logger.success('Delegatee role initialized successfully.');
  }

  /**
   * Creates an instance of the `AwDelegatee` class.
   * Handles errors related to missing private keys or insufficient balances by prompting the user for input.
   *
   * @param litNetwork - The Lit network to use for the Delegatee role.
   * @param privateKey - Optional. The private key for the Delegatee role.
   * @returns A promise that resolves to an instance of the `AwDelegatee` class.
   * @throws If initialization fails, the function logs an error and exits the process.
   */
  private static async createAwDelegatee(
    litNetwork: LitNetwork,
    privateKey?: string
  ): Promise<AwDelegatee> {
    let awDelegatee: AwDelegatee;
    try {
      // Attempt to create the AwDelegatee instance.
      awDelegatee = await AwDelegatee.create(privateKey, { litNetwork });
    } catch (error) {
      // Handle specific errors related to missing private keys or insufficient balances.
      if (error instanceof AwSignerError) {
        if (error.type === AwSignerErrorType.DELEGATEE_MISSING_PRIVATE_KEY) {
          // Prompt the user for a private key if it is missing.
          const privateKey = await promptDelegateeInit();
          return Delegatee.createAwDelegatee(litNetwork, privateKey);
        }

        if (
          error.type ===
          AwSignerErrorType.INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT
        ) {
          // Prompt the user to fund the account if the balance is insufficient.
          const hasFunded = await promptDelegateeInsufficientBalance();
          if (hasFunded) {
            return Delegatee.createAwDelegatee(litNetwork, privateKey);
          }
        }
      }

      // Log any other errors and exit the process.
      logger.error('Failed to initialize Delegatee role', error as Error);
      process.exit(1);
    }

    return awDelegatee;
  }

  public static async create(
    litNetwork: LitNetwork,
    intentMatcher: IntentMatcher | null = null
  ) {
    logger.info('Initializing Delegatee role...');
    const awDelegatee = await Delegatee.createAwDelegatee(litNetwork);
    const delegatee = new Delegatee(awDelegatee);
    delegatee.intentMatcher = intentMatcher;
    return delegatee;
  }

  /**
   * Displays the Delegatee menu and handles user-selected actions.
   * The menu allows the Delegatee to perform various operations such as retrieving delegated PKPs, registered tools, and executing tools.
   *
   * @param delegatee - An instance of the `Delegatee` class.
   * @returns A promise that resolves when the menu interaction is complete.
   */
  public static async showMenu(delegatee: Delegatee) {
    // Prompt the user to select an action from the Delegatee menu.
    const option = await promptDelegateeMenu();

    // Handle the selected action.
    switch (option) {
      case 'getDelegatedPkps':
        await handleGetDelegatedPkps(delegatee.awDelegatee);
        break;
      case 'getRegisteredTools':
        await handleGetRegisteredTools(delegatee.awDelegatee);
        break;
      case 'getToolPolicy':
        await handleGetToolPolicy(delegatee.awDelegatee);
        break;
      case 'getToolViaIntent':
        if (delegatee.intentMatcher === null) {
          const intentMatcher = await handleGetIntentMatcher(
            delegatee.awDelegatee
          );
          delegatee.setIntentMatcher(intentMatcher);
        }

        await handleGetToolViaIntent(
          delegatee.awDelegatee,
          delegatee.intentMatcher as IntentMatcher
        );
        break;
      case 'executeToolViaIntent':
        if (delegatee.intentMatcher === null) {
          const intentMatcher = await handleGetIntentMatcher(
            delegatee.awDelegatee
          );
          delegatee.setIntentMatcher(intentMatcher);
        }

        await handleExecuteToolViaIntent(
          delegatee.awDelegatee,
          delegatee.intentMatcher as IntentMatcher
        );
        break;
      case 'executeTool':
        await handleExecuteTool(delegatee.awDelegatee);
        break;
      default:
        // Log an error and exit if an invalid option is selected.
        logger.error('Invalid option selected');
        process.exit(1);
    }

    // Recursively show the menu again to allow further actions.
    await Delegatee.showMenu(delegatee);
  }

  public setIntentMatcher(intentMatcher: IntentMatcher) {
    this.intentMatcher = intentMatcher;
  }

  public disconnect() {
    this.awDelegatee.disconnect();
  }
}
