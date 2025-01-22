import { checkLitAuthAddressIsDelegatee } from './utils/check-lit-auth-address-is-delegatee';
import { getPolicyParameters } from './utils/get-policy-parameters';

declare global {
  // Required Inputs
  const pkpToolRegistryContract: any;
  const pkpTokenId: string;
  const delegateeAddress: string;
  const tokenInfo: {
    amount: any;
    tokenIn: string;
    recipientAddress: string;
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
    'erc20Transfer',
    delegateeAddress,
    ['maxAmount', 'allowedTokens', 'allowedRecipients']
  );

  let maxAmount: any;
  let allowedTokens: string[] = [];
  let allowedRecipients: string[] = [];

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
      case 'allowedRecipients':
        allowedRecipients = ethers.utils.defaultAbiCoder.decode(
          ['address[]'],
          parameter.value
        )[0];
        break;
    }
  }

  if (tokenInfo.amount.gt(maxAmount)) {
    throw new Error(
      `Amount ${tokenInfo.amount} exceeds the maximum amount ${maxAmount}`
    );
  }

  if (
    allowedTokens.length > 0 &&
    !allowedTokens
      .map((addr: string) => ethers.utils.getAddress(addr))
      .includes(ethers.utils.getAddress(tokenInfo.tokenIn))
  ) {
    throw new Error(
      `Token ${
        params.tokenIn
      } not allowed. Allowed tokens: ${allowedTokens.join(', ')}`
    );
  }

  if (
    allowedRecipients.length > 0 &&
    !allowedRecipients
      .map((addr: string) => ethers.utils.getAddress(addr))
      .includes(ethers.utils.getAddress(tokenInfo.recipientAddress))
  ) {
    throw new Error(
      `Recipient ${
        params.recipientAddress
      } not allowed. Allowed recipients: ${allowedRecipients.join(', ')}`
    );
  }

  console.log('Policy parameters validated');
};
