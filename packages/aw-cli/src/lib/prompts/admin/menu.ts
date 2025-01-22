// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

type ManageChoice = 'tools' | 'policies' | 'delegatees' | 'transferOwnership';
type Choice = { title: string; value: string };

const categoryChoices: Record<
  Exclude<ManageChoice, 'transferOwnership'>,
  Choice[]
> = {
  tools: [
    // View current state
    { title: 'List Registered Tools', value: 'getRegisteredTools' },
    // Basic tool management
    { title: 'Register Tool', value: 'registerTool' },
    { title: 'Remove Tool', value: 'removeTool' },
    // Tool state management (requires tool to be registered first)
    { title: 'Enable Tool', value: 'enableTool' },
    { title: 'Disable Tool', value: 'disableTool' },
    // Delegatee permissions (requires tool to be registered first)
    { title: 'Permit Tool for Delegatee', value: 'permitToolForDelegatee' },
    { title: 'Unpermit Tool for Delegatee', value: 'unpermitToolForDelegatee' },
  ],
  policies: [
    { title: 'Get Tool Policy', value: 'getToolPolicy' },
    { title: 'Set Tool Policy', value: 'setToolPolicy' },
    { title: 'Remove Tool Policy', value: 'removeToolPolicy' },
    { title: 'Get Policy Parameters', value: 'getPolicyParameters' },
    { title: 'Set Policy Parameters', value: 'setPolicyParameters' },
    { title: 'Remove Policy Parameters', value: 'removePolicyParameters' },
  ],
  delegatees: [
    { title: 'List Delegatees', value: 'getDelegatees' },
    { title: 'Check if Address is Delegatee', value: 'isDelegatee' },
    { title: 'Add Delegatee', value: 'addDelegatee' },
    { title: 'Remove Delegatee', value: 'removeDelegatee' },
  ],
};

export const promptAdminManageOrMintMenu = async (numberOfPkps: number) => {
  const { action } = await prompts({
    type: 'select',
    name: 'action',
    message: 'What would you like to do?',
    choices: [
      {
        title: 'Manage Existing Agent Wallet',
        value: 'manage',
        disabled: numberOfPkps === 0,
      },
      { title: 'Mint New Agent Wallet', value: 'mint' },
    ],
  });

  if (!action) {
    logger.error('No action selected');
    process.exit(1);
  }

  return action;
};

/**
 * Displays a menu of available admin actions and prompts the user to select an action.
 * This function ensures that an option is selected before proceeding. If no option is selected,
 * the function logs an error and exits the process.
 *
 * @returns The selected admin action as a string.
 */
export const promptAdminManagePkpMenu = async () => {
  const response = await prompts({
    type: 'select',
    name: 'manageChoice',
    message: 'What would you like to manage?',
    choices: [
      { title: 'Tools', value: 'tools' },
      { title: 'Policies', value: 'policies' },
      { title: 'Delegatees', value: 'delegatees' },
      { title: 'Transfer Ownership', value: 'transferOwnership' },
    ],
  });

  const manageChoice = response.manageChoice as ManageChoice;
  if (!manageChoice) {
    logger.error('No category selected');
    process.exit(1);
  }

  if (manageChoice === 'transferOwnership') {
    return manageChoice;
  }

  // Then prompt for specific action within the chosen category
  const { option } = await prompts({
    type: 'select',
    name: 'option',
    message: `Select a ${manageChoice} action:`,
    choices: categoryChoices[manageChoice],
  });

  // If no option is selected, log an error and exit the process.
  if (!option) {
    logger.error('No option selected');
    process.exit(1);
  }

  // Return the selected admin action.
  return option;
};
