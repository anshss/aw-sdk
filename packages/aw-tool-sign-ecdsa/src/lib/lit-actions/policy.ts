import {
  checkLitAuthAddressIsDelegatee,
  getPolicyParameters,
} from '@lit-protocol/aw-tool';

declare global {
  // Required Inputs
  const pkpToolRegistryContract: any;
  const pkpTokenId: string;
  const toolIpfsCid: string;
  const delegateeAddress: string;
  const toolParameters: {
    message: string;
  };
}

(async () => {
  const isDelegatee = await checkLitAuthAddressIsDelegatee(
    pkpToolRegistryContract,
    pkpTokenId
  );
  if (!isDelegatee) {
    throw new Error(
      `Session signer ${ethers.utils.getAddress(
        LitAuth.authSigAddress
      )} is not a delegatee for PKP ${pkpTokenId}`
    );
  }

  const policyParameters = await getPolicyParameters(
    pkpToolRegistryContract,
    pkpTokenId,
    toolIpfsCid,
    delegateeAddress,
    ['allowedPrefixes']
  );

  let allowedPrefixes: string[] = [];

  for (const parameter of policyParameters) {
    switch (parameter.name) {
      case 'maxAmount':
        allowedPrefixes = ethers.utils.defaultAbiCoder.decode(
          ['string[] allowedPrefixes'],
          parameter.value
        )[0];
        break;
    }
  }

  // Validate message prefix
  if (
    !allowedPrefixes.some((prefix: string) =>
      toolParameters.message.startsWith(prefix)
    )
  ) {
    throw new Error(
      `Message does not start with any allowed prefix. Allowed prefixes: ${allowedPrefixes.join(
        ', '
      )}`
    );
  }

  console.log('Policy parameters validated');
})();
