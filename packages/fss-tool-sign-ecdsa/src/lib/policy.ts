import { z } from 'zod';
import { ethers } from 'ethers';

const policySchema = z.object({
  type: z.literal('SignEcdsa'),
  version: z.string(),
  allowedPrefixes: z.array(z.string()),
});

function encodePolicy(policy: SignEcdsaPolicyType): string {
  policySchema.parse(policy);

  return ethers.utils.defaultAbiCoder.encode(
    ['tuple(string[] allowedPrefixes)'],
    [
      {
        allowedPrefixes: policy.allowedPrefixes,
      },
    ]
  );
}

function decodePolicy(encodedPolicy: string): SignEcdsaPolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ['tuple(string[] allowedPrefixes)'],
    encodedPolicy
  )[0];

  const policy: SignEcdsaPolicyType = {
    type: 'SignEcdsa',
    version: '1.0.0',
    allowedPrefixes: decoded.allowedPrefixes,
  };

  return policySchema.parse(policy);
}

export type SignEcdsaPolicyType = z.infer<typeof policySchema>;

export const SignEcdsaPolicy = {
  type: {} as SignEcdsaPolicyType,
  version: '1.0.0',
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
