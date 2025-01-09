import { Admin as FssAdmin, type LitNetwork } from '@lit-protocol/agent-wallet';
import { FssSignerError, FssSignerErrorType } from '@lit-protocol/aw-signer';

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
  // Private instance of the FssAdmin class.
  private fssAdmin: FssAdmin;

  /**
   * Private constructor for the Admin class.
   * @param fssAdmin - An instance of the `FssAdmin` class.
   */
  private constructor(fssAdmin: FssAdmin) {
    this.fssAdmin = fssAdmin;
    logger.success('Admin role initialized successfully.');
  }

  /**
   * Creates an instance of the `FssAdmin` class.
   * Handles errors related to missing private keys or insufficient balances by prompting the user for input.
   *
   * @param litNetwork - The Lit network to use for the Admin role.
   * @param privateKey - Optional. The private key for the Admin role.
   * @returns A promise that resolves to an instance of the `FssAdmin` class.
   * @throws If initialization fails, the function logs an error and exits the process.
   */
  private static async createFssAdmin(
    litNetwork: LitNetwork,
    privateKey?: string
  ): Promise<FssAdmin> {
    let fssAdmin: FssAdmin;
    try {
      // Attempt to create the FssAdmin instance.
      fssAdmin = await FssAdmin.create(
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
      if (error instanceof FssSignerError) {
        if (error.type === FssSignerErrorType.ADMIN_MISSING_PRIVATE_KEY) {
          // Prompt the user for a private key if it is missing.
          const privateKey = await promptAdminInit();
          return Admin.createFssAdmin(litNetwork, privateKey);
        }

        if (error.type === FssSignerErrorType.INSUFFICIENT_BALANCE_PKP_MINT) {
          // Prompt the user to fund the account if the balance is insufficient.
          const hasFunded = await promptAdminInsufficientBalance();
          if (hasFunded) {
            return Admin.createFssAdmin(litNetwork, privateKey);
          }
        }
      }

      // Log any other errors and exit the process.
      logger.error('Failed to initialize Admin role', error as Error);
      process.exit(1);
    }

    return fssAdmin;
  }

  /**
   * Creates an instance of the `Admin` class.
   * @param litNetwork - The Lit network to use for the Admin role.
   * @returns A promise that resolves to an instance of the `Admin` class.
   */
  public static async create(litNetwork: LitNetwork) {
    logger.info('Initializing Admin role...');
    const fssAdmin = await Admin.createFssAdmin(litNetwork);
    return new Admin(fssAdmin);
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
    this.fssAdmin.disconnect();
  }
}
