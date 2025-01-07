import { BaseEthereumAddressSchema } from '@lit-protocol/fss-tool';
import { z } from 'zod';
import { ethers } from 'ethers';

const policySchema = z.object({
  type: z.literal('ERC20Transfer'),
  version: z.string(),
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

function encodePolicy(policy: ERC20TransferPolicyType): string {
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

function decodePolicy(encodedPolicy: string): ERC20TransferPolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    encodedPolicy
  )[0];

  const policy: ERC20TransferPolicyType = {
    type: 'ERC20Transfer',
    version: '1.0.0',
    maxAmount: decoded.maxAmount.toString(),
    allowedTokens: decoded.allowedTokens,
    allowedRecipients: decoded.allowedRecipients,
  };

  return policySchema.parse(policy);
}

export type ERC20TransferPolicyType = z.infer<typeof policySchema>;

export const ERC20TransferPolicy = {
  type: {} as ERC20TransferPolicyType,
  version: '1.0.0',
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
