import { z } from 'zod';
import type { FssTool } from '@lit-protocol/fss-tool';

import { IPFS_CID } from './ipfs';
import { SigningSimplePolicy, type SigningSimplePolicyType } from './policy';

/**
 * Parameters required for the Signing Simple Lit Action
 * @property message - The message to sign
 */
export interface SigningSimpleLitActionParameters {
  message: string;
}

/**
 * Zod schema for validating SigningSimpleLitActionParameters
 */
const SigningSimpleLitActionSchema = z.object({
  message: z.string(),
});

/**
 * Descriptions of each parameter for the Signing Simple Lit Action
 * These descriptions are designed to be consumed by LLMs to understand the required parameters
 */
const SigningSimpleLitActionParameterDescriptions = {
  message: 'The message you want to sign.',
} as const;

/**
 * Validate parameters and return detailed error messages if invalid
 */
const validateSigningSimpleParameters = (
  params: unknown
): true | Array<{ param: string; error: string }> => {
  const result = SigningSimpleLitActionSchema.safeParse(params);
  if (result.success) {
    return true;
  }

  return result.error.issues.map((issue) => ({
    param: issue.path[0] as string,
    error: issue.message,
  }));
};

export const SigningSimple: FssTool<
  SigningSimpleLitActionParameters,
  SigningSimplePolicyType
> = {
  name: 'SigningSimple',
  description: 'A Lit Action that allows signing for a set of message prefixes.',
  ipfsCid: IPFS_CID,

  parameters: {
    type: {} as SigningSimpleLitActionParameters,
    schema: SigningSimpleLitActionSchema,
    descriptions: SigningSimpleLitActionParameterDescriptions,
    validate: validateSigningSimpleParameters,
  },

  policy: SigningSimplePolicy,
};
