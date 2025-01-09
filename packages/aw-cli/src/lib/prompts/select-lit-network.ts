import prompts from 'prompts';
import type { LitNetwork } from '@lit-protocol/agent-wallet';

/**
 * Prompts the user to select a Lit network from a predefined list of options.
 * The user is presented with a menu of Lit networks, including development, test, and production environments.
 * If no network is selected, the function logs an error message and exits the process.
 *
 * @returns A promise that resolves to the selected `LitNetwork` value.
 * @throws If no network is selected, the function logs an error and exits the process with a status code of 1.
 */
export const promptSelectLitNetwork = async (): Promise<LitNetwork> => {
  // Prompt the user to select a Lit network.
  const { network } = await prompts({
    type: 'select', // Use a select input type for the menu.
    name: 'network', // The name of the selected network.
    message: 'Select a Lit network:', // The message displayed to the user.
    choices: [
      // The list of available Lit networks.
      {
        title: 'Datil Dev',
        description: 'Development network',
        value: 'datil-dev',
      },
      {
        title: 'Datil Test',
        description: 'Pre-production test network',
        value: 'datil-test',
      },
      {
        title: 'Datil',
        description: 'Production network',
        value: 'datil',
      },
    ],
  });

  // If no network is selected, log an error and exit the process.
  if (!network) {
    console.log('❌ Lit network selection is required to proceed.');
    process.exit(1);
  }

  // Return the selected network.
  return network;
};
