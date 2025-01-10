import prompts from 'prompts';
import { type PkpInfo } from '@lit-protocol/agent-wallet';

import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to select a PKP (Programmable Key Pair) from a list of delegated PKPs.
 * The user is presented with a menu of PKPs, each identified by its Ethereum address and token ID.
 *
 * @param pkps - An array of `DelegatedPkpInfo` objects representing the available PKPs.
 * @returns A promise that resolves to the selected PKP as a `DelegatedPkpInfo` object.
 * @throws {AwCliError} If the user cancels the selection or no PKP is selected, an error of type `DELEGATEE_SELECT_PKP_CANCELLED` is thrown.
 */
export const promptSelectPkp = async (pkps: PkpInfo[]) => {
  // Prompt the user to select a PKP from the provided list.
  const selectedPkp = await prompts({
    type: 'select', // Use a select input type for the menu.
    name: 'pkp', // The name of the selected PKP.
    message: 'Select a PKP:', // The message displayed to the user.
    choices: pkps.map((pkp, i) => ({
      title: `${i + 1}: ${pkp.info.ethAddress} (${pkp.info.tokenId})`, // Display the PKP's Ethereum address and token ID.
      value: pkp, // The value of the selected PKP.
    })),
  });

  // If no PKP is selected, throw an error.
  if (!selectedPkp.pkp) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_SELECT_PKP_CANCELLED,
      'No PKP selected'
    );
  }

  // Return the selected PKP.
  return selectedPkp.pkp as PkpInfo;
};
