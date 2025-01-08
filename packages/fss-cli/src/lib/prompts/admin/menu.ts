// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the logger utility for logging messages.
import { logger } from '../../utils/logger';

/**
 * Displays a menu of available admin actions and prompts the user to select an action.
 * This function ensures that an option is selected before proceeding. If no option is selected,
 * the function logs an error and exits the process.
 *
 * @returns The selected admin action as a string.
 */
export const promptAdminMenu = async () => {
  // Prompt the user to select an admin action from the menu.
  const { option } = await prompts({
    type: 'select', // Use a select input for the menu.
    name: 'option',
    message: 'Select an action:',
    choices: [
      { title: 'Permit Tool', value: 'permitTool' },
      { title: 'Remove Tool', value: 'removeTool' },
      { title: 'List Permitted Tools', value: 'getRegisteredTools' },
      { title: 'Get Tool Policy', value: 'getToolPolicy' },
      { title: 'Set Tool Policy', value: 'setToolPolicy' },
      { title: 'Remove Tool Policy', value: 'removeToolPolicy' },
      { title: 'List Delegatees', value: 'getDelegatees' },
      { title: 'Check if Address is Delegatee', value: 'isDelegatee' },
      { title: 'Add Delegatee', value: 'addDelegatee' },
      { title: 'Remove Delegatee', value: 'removeDelegatee' },
      { title: 'Batch Add Delegatees', value: 'batchAddDelegatees' },
      { title: 'Batch Remove Delegatees', value: 'batchRemoveDelegatees' },
    ],
  });

  // If no option is selected, log an error and exit the process.
  if (!option) {
    logger.error('No option selected');
    process.exit(1);
  }

  // Return the selected admin action.
  return option;
};
