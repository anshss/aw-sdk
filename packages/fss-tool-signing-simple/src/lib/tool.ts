import { z } from 'zod';
import type { FssTool, SupportedLitNetwork } from '@lit-protocol/fss-tool';

import { SigningSimplePolicy, type SigningSimplePolicyType } from './policy';
import { NETWORK_CONFIGS, type NetworkConfig } from './networks';
import { IPFS_CIDS } from './ipfs';

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

/**
 * Create a network-specific SendERC20 tool
 */
const createNetworkTool = (
  network: SupportedLitNetwork,
  config: NetworkConfig
): FssTool<SigningSimpleLitActionParameters, SigningSimplePolicyType> => ({
  name: 'SigningSimple',
  description: `A Lit Action that signs a message with an allowlist of message prefixes, using the ${config.litNetwork} network for signing.`,
  ipfsCid: IPFS_CIDS[network],
  parameters: {
    type: {} as SigningSimpleLitActionParameters,
    schema: SigningSimpleLitActionSchema,
    descriptions: SigningSimpleLitActionParameterDescriptions,
    validate: validateSigningSimpleParameters,
  },
  policy: SigningSimplePolicy,
});

/**
 * Export network-specific SendERC20 tools
 */
export const SigningSimple = Object.entries(NETWORK_CONFIGS).reduce(
  (acc, [network, config]) => ({
    ...acc,
    [network]: createNetworkTool(network as SupportedLitNetwork, config),
  }),
  {} as Record<
    SupportedLitNetwork,
    FssTool<SigningSimpleLitActionParameters, SigningSimplePolicyType>
  >
);
