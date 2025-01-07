import { BaseEthereumAddressSchema } from '@lit-protocol/fss-tool';
import { z } from 'zod';
import { ethers } from 'ethers';

const policySchema = z.object({
  type: z.literal('UniswapSwap'),
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
});

function encodePolicy(policy: UniswapSwapPolicyType): string {
  policySchema.parse(policy);

  return ethers.utils.defaultAbiCoder.encode(
    ['tuple(uint256 maxAmount, address[] allowedTokens)'],
    [
      {
        maxAmount: policy.maxAmount,
        allowedTokens: policy.allowedTokens,
      },
    ]
  );
}

function decodePolicy(encodedPolicy: string): UniswapSwapPolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ['tuple(uint256 maxAmount, address[] allowedTokens)'],
    encodedPolicy
  )[0];

  const policy: UniswapSwapPolicyType = {
    type: 'UniswapSwap',
    version: '1.0.0',
    maxAmount: decoded.maxAmount.toString(),
    allowedTokens: decoded.allowedTokens,
  };

  return policySchema.parse(policy);
}

export type UniswapSwapPolicyType = z.infer<typeof policySchema>;

export const UniswapSwapPolicy = {
  type: {} as UniswapSwapPolicyType,
  version: '1.0.0',
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
