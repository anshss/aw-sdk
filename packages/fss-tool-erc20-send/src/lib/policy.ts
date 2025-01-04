import { BaseEthereumAddressSchema } from '@lit-protocol/fss-tool';
import { z } from 'zod';
import { ethers } from 'ethers';

const policySchema = z.object({
  type: z.literal('SendERC20'),
  maxAmount: z.string().refine(
    (val) => {
      try {
        const bn = ethers.BigNumber.from(val);
        return !bn.isNegative();
      } catch {
        return false;
      }
    },
    { message: 'Invalid amount format. Must be a non-negative integer.' }
  ),
  allowedTokens: z.array(BaseEthereumAddressSchema),
  allowedRecipients: z.array(BaseEthereumAddressSchema),
});

function encodePolicy(policy: SendERC20PolicyType): string {
  policySchema.parse(policy);

  return ethers.utils.defaultAbiCoder.encode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    [
      {
        maxAmount: policy.maxAmount,
        allowedTokens: policy.allowedTokens,
        allowedRecipients: policy.allowedRecipients,
      },
    ]
  );
}

function decodePolicy(encodedPolicy: string): SendERC20PolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    encodedPolicy
  )[0];

  const policy: SendERC20PolicyType = {
    type: 'SendERC20',
    maxAmount: decoded.maxAmount.toString(),
    allowedTokens: decoded.allowedTokens,
    allowedRecipients: decoded.allowedRecipients,
  };

  return policySchema.parse(policy);
}

export type SendERC20PolicyType = z.infer<typeof policySchema>;

export const SendERC20Policy = {
  type: {} as SendERC20PolicyType,
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
