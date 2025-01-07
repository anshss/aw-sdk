import prompts from 'prompts';
import { logger } from '../../utils/logger';

/**
 * Prompts the user with a menu of actions related to delegatee operations.
 * The user can select from options such as retrieving delegated PKPs, registered tools, tool policies, or executing a tool.
 *
 * @returns A promise that resolves to the selected action's value (e.g., 'getDelegatedPkps', 'getRegisteredTools', etc.).
 * If no option is selected, the function logs an error and exits the process with a status code of 1.
 */
export const promptDelegateeMenu = async () => {
  // Prompt the user with a menu of actions using the `prompts` library.
  const { option } = await prompts({
    type: 'select', // Use a select input type for the menu.
    name: 'option', // The name of the selected option.
    message: 'Select an action:', // The message displayed to the user.
    choices: [ // The list of available actions.
      { title: 'Get Delegated PKPs', value: 'getDelegatedPkps' },
      { title: 'Get Registered Tools', value: 'getRegisteredTools' },
      { title: 'Get Tool Policy', value: 'getToolPolicy' },
      { title: 'Execute Tool', value: 'executeTool' },
    ],
  });

  // If no option is selected, log an error and exit the process.
  if (!option) {
    logger.error('No option selected');
    process.exit(1);
  }

  // Return the selected option's value.
  return option;
};
