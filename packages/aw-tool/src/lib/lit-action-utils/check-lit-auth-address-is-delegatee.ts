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
  console.log(
    `Checking if Lit Auth address: ${LitAuth.authSigAddress} is a delegatee for PKP ${pkpTokenId}...`
  );

  // Check if the session signer is a delegatee
  const sessionSigner = ethers.utils.getAddress(LitAuth.authSigAddress);

  if (await pkpToolRegistryContract.isPkpDelegatee(pkpTokenId, sessionSigner)) {
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
