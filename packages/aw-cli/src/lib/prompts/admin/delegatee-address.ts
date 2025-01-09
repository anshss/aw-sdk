// Import the prompts library for user interaction.
import prompts from 'prompts';

// Import the ethers library for Ethereum address validation.
import { ethers } from 'ethers';

// Import custom error types and utilities.
import { AwCliError, AwCliErrorType } from '../../errors';

/**
 * Prompts the user to enter a delegatee address and validates it.
 * This function ensures the entered address is a valid Ethereum address and handles user cancellation.
 *
 * @returns The validated and normalized Ethereum address.
 * @throws AwCliError - If the user cancels the operation or provides an invalid address.
 */
export const promptDelegateeAddress = async () => {
  // Prompt the user to enter a delegatee address.
  const { address } = await prompts({
    type: 'text',
    name: 'address',
    message: 'Enter the delegatee address:',
    validate: (value) => {
      try {
        // Ensure the address is not empty.
        if (!value) return 'Address is required';

        // Validate the Ethereum address format.
        ethers.utils.getAddress(value);
        return true;
      } catch {
        // Return an error message if the address is invalid.
        return 'Invalid Ethereum address';
      }
    },
  });

  // If the user cancels the prompt or provides an empty address, throw an error.
  if (!address) {
    throw new AwCliError(
      AwCliErrorType.ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED,
      'Delegatee operation cancelled.'
    );
  }

  // Return the validated and normalized Ethereum address.
  return address;
};
