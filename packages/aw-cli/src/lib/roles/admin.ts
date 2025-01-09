import { Admin as AwAdmin, type LitNetwork } from '@lit-protocol/agent-wallet';
import { AwSignerError, AwSignerErrorType } from '@lit-protocol/aw-signer';

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

/**
 * The `Admin` class is responsible for managing the Admin role in the Lit Protocol.
 * It initializes the Admin role, handles user interactions via a menu, and delegates actions to appropriate handlers.
 */
export class Admin {
  // Private instance of the AwAdmin class.
  private awAdmin: AwAdmin;

  /**
   * Private constructor for the Admin class.
   * @param awAdmin - An instance of the `AwAdmin` class.
   */
  private constructor(awAdmin: AwAdmin) {
    this.awAdmin = awAdmin;
    logger.success('Admin role initialized successfully.');
  }

  /**
   * Creates an instance of the `AwAdmin` class.
   * Handles errors related to missing private keys or insufficient balances by prompting the user for input.
   *
   * @param litNetwork - The Lit network to use for the Admin role.
   * @param privateKey - Optional. The private key for the Admin role.
   * @returns A promise that resolves to an instance of the `AwAdmin` class.
   * @throws If initialization fails, the function logs an error and exits the process.
   */
  private static async createAwAdmin(
    litNetwork: LitNetwork,
    privateKey?: string
  ): Promise<AwAdmin> {
    let awAdmin: AwAdmin;
    try {
      // Attempt to create the AwAdmin instance.
      awAdmin = await AwAdmin.create(
        {
          type: 'eoa',
          privateKey,
        },
        {
          litNetwork,
        }
      );
    } catch (error) {
      // Handle specific errors related to missing private keys or insufficient balances.
      if (error instanceof AwSignerError) {
        if (error.type === AwSignerErrorType.ADMIN_MISSING_PRIVATE_KEY) {
          // Prompt the user for a private key if it is missing.
          const privateKey = await promptAdminInit();
          return Admin.createAwAdmin(litNetwork, privateKey);
        }

        if (error.type === AwSignerErrorType.INSUFFICIENT_BALANCE_PKP_MINT) {
          // Prompt the user to fund the account if the balance is insufficient.
          const hasFunded = await promptAdminInsufficientBalance();
          if (hasFunded) {
            return Admin.createAwAdmin(litNetwork, privateKey);
          }
        }
      }

      // Log any other errors and exit the process.
      logger.error('Failed to initialize Admin role', error as Error);
      process.exit(1);
    }

    return awAdmin;
  }

  /**
   * Creates an instance of the `Admin` class.
   * @param litNetwork - The Lit network to use for the Admin role.
   * @returns A promise that resolves to an instance of the `Admin` class.
   */
  public static async create(litNetwork: LitNetwork) {
    logger.info('Initializing Admin role...');
    const awAdmin = await Admin.createAwAdmin(litNetwork);
    return new Admin(awAdmin);
  }

  /**
   * Displays the Admin menu and handles user-selected actions.
   * The menu allows the Admin to perform various operations such as permitting tools, managing delegatees, and setting policies.
   *
   * @param admin - An instance of the `Admin` class.
   * @returns A promise that resolves when the menu interaction is complete.
   */
  public static async showMenu(admin: Admin) {
    // Prompt the user to select an action from the Admin menu.
    const option = await promptAdminMenu();

    // Handle the selected action.
    switch (option) {
      case 'permitTool':
        await handlePermitTool(admin.awAdmin);
        break;
      case 'removeTool':
        await handleRemoveTool(admin.awAdmin);
        break;
      case 'getRegisteredTools':
        await handleGetTools(admin.awAdmin);
        break;
      case 'getToolPolicy':
        await handleGetToolPolicy(admin.awAdmin);
        break;
      case 'setToolPolicy':
        await handleSetToolPolicy(admin.awAdmin);
        break;
      case 'removeToolPolicy':
        await handleRemoveToolPolicy(admin.awAdmin);
        break;
      case 'getDelegatees':
        await handleGetDelegatees(admin.awAdmin);
        break;
      case 'isDelegatee':
        await handleIsDelegatee(admin.awAdmin);
        break;
      case 'addDelegatee':
        await handleAddDelegatee(admin.awAdmin);
        break;
      case 'removeDelegatee':
        await handleRemoveDelegatee(admin.awAdmin);
        break;
      case 'batchAddDelegatees':
        await handleBatchAddDelegatee(admin.awAdmin);
        break;
      case 'batchRemoveDelegatees':
        await handleBatchRemoveDelegatee(admin.awAdmin);
        break;
      default:
        // Log an error and exit if an invalid option is selected.
        logger.error('Invalid option selected');
        process.exit(1);
    }

    // Recursively show the menu again to allow further actions.
    await Admin.showMenu(admin);
  }

  /**
   * Disconnects the Admin instance from the Lit network.
   */
  public disconnect() {
    this.awAdmin.disconnect();
  }
}
