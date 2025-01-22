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
    amountIn: any;
    tokenIn: string;
    tokenOut: string;
  };
}

export default async () => {
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
    ['maxAmount', 'allowedTokens']
  );

  let maxAmount: any;
  let allowedTokens: string[] = [];

  for (const parameter of policyParameters) {
    switch (parameter.name) {
      case 'maxAmount':
        maxAmount = ethers.utils.defaultAbiCoder.decode(
          ['uint256'],
          parameter.value
        )[0];
        break;
      case 'allowedTokens':
        allowedTokens = ethers.utils.defaultAbiCoder.decode(
          ['address[]'],
          parameter.value
        )[0];
        break;
    }
  }

  if (toolParameters.amountIn.gt(maxAmount)) {
    throw new Error(
      `Amount ${toolParameters.amountIn} exceeds the maximum amount ${maxAmount}`
    );
  }

  if (
    allowedTokens.length > 0 &&
    !allowedTokens
      .map((addr: string) => ethers.utils.getAddress(addr))
      .includes(ethers.utils.getAddress(toolParameters.tokenIn))
  ) {
    throw new Error(
      `Token ${
        params.tokenIn
      } not allowed. Allowed tokens: ${allowedTokens.join(', ')}`
    );
  }

  if (
    allowedTokens.length > 0 &&
    !allowedTokens
      .map((addr: string) => ethers.utils.getAddress(addr))
      .includes(ethers.utils.getAddress(toolParameters.tokenOut))
  ) {
    throw new Error(
      `Token ${
        params.tokenOut
      } not allowed. Allowed tokens: ${allowedTokens.join(', ')}`
    );
  }

  console.log('Policy parameters validated');
};
