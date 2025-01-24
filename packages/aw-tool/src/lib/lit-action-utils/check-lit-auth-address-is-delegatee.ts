/**
 * Checks if the current Lit Auth session signer is a delegatee for the specified PKP.
 * This function verifies whether the address associated with the current authentication
 * signature has delegatee permissions for the given PKP token.
 * 
 * @param pkpToolRegistryContract - The PKP Tool Registry contract instance used to check delegatee status.
 * @param pkpTokenId - The token ID of the PKP to check delegatee status against.
 * @returns A promise that resolves to true if the session signer is a delegatee, false otherwise.
 */
export const checkLitAuthAddressIsDelegatee = async (
  pkpToolRegistryContract: any,
  pkpTokenId: string
) => {
  // Check if the session signer is a delegatee
  const sessionSigner = ethers.utils.getAddress(LitAuth.authSigAddress);

  console.log(
    `Checking if Lit Auth address: ${sessionSigner} is a delegatee for PKP ${pkpTokenId}...`
  );

  let isDelegatee = false;
  try {
    isDelegatee = await pkpToolRegistryContract.isPkpDelegatee(
      pkpTokenId,
      sessionSigner
    );
  } catch (error) {
    throw new Error(
      `Error calling pkpToolRegistryContract.isPkpDelegatee: ${error}`
    );
  }

  if (isDelegatee) {
    console.log(
      `Session signer ${sessionSigner} is a delegatee for PKP ${pkpTokenId}`
    );
    return true;
  }

  console.log(
    `Session signer ${sessionSigner} is not a delegatee for PKP ${pkpTokenId}`
  );
  return false;
};
