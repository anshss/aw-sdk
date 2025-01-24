/**
 * Checks if the session signer is a delegatee for the PKP.
 * @param {any} pkpToolRegistryContract - The PKP Tool Registry contract instance.
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
