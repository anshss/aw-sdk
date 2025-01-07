import { z } from 'zod';
import { ethers } from 'ethers';

const policySchema = z.object({
  type: z.literal('SigningSimple'),
  version: z.string(),
  allowedPrefixes: z.array(z.string()),
});

function encodePolicy(policy: SigningSimplePolicyType): string {
  policySchema.parse(policy);

  return ethers.utils.defaultAbiCoder.encode(
    [
      'tuple(string[] allowedPrefixes)',
    ],
    [
      {
        allowedPrefixes: policy.allowedPrefixes,
      },
    ]
  );
}

function decodePolicy(encodedPolicy: string): SigningSimplePolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    [
      'tuple(string[] allowedPrefixes)',
    ],
    encodedPolicy
  )[0];

  const policy: SigningSimplePolicyType = {
    type: 'SigningSimple',
    version: '1.0.0',
    allowedPrefixes: decoded.allowedPrefixes,
  };

  return policySchema.parse(policy);
}

export type SigningSimplePolicyType = z.infer<typeof policySchema>;

export const SigningSimplePolicy = {
  type: {} as SigningSimplePolicyType,
  version: '1.0.0',
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
