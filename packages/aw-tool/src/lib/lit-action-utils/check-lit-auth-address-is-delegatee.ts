/**
 * Checks if the session signer is a delegatee for the PKP.
 * @param {any} pkpToolRegistryContract - The PKP Tool Registry contract instance.
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
