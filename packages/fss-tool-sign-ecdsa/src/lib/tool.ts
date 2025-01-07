import { z } from 'zod';
import type { FssTool, SupportedLitNetwork } from '@lit-protocol/fss-tool';

import { SignEcdsaPolicy, type SignEcdsaPolicyType } from './policy';
import { NETWORK_CONFIGS, type NetworkConfig } from './networks';
import { IPFS_CIDS } from './ipfs';

/**
 * Parameters required for the Signing ECDSA Lit Action
 * @property message - The message to sign
 */
export interface SignEcdsaLitActionParameters {
  message: string;
}

/**
 * Zod schema for validating SignEcdsaLitActionParameters
 */
const SignEcdsaLitActionSchema = z.object({
  message: z.string(),
});

/**
 * Descriptions of each parameter for the Signing ECDSA Lit Action
 * These descriptions are designed to be consumed by LLMs to understand the required parameters
 */
const SignEcdsaLitActionParameterDescriptions = {
  message: 'The message you want to sign.',
} as const;

/**
 * Validate parameters and return detailed error messages if invalid
 */
const validateSignEcdsaParameters = (
  params: unknown
): true | Array<{ param: string; error: string }> => {
  const result = SignEcdsaLitActionSchema.safeParse(params);
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
): FssTool<SignEcdsaLitActionParameters, SignEcdsaPolicyType> => ({
  name: 'SignEcdsa',
  description: `A Lit Action that signs a message with an allowlist of message prefixes, using the ${config.litNetwork} network for signing.`,
  ipfsCid: IPFS_CIDS[network],
  parameters: {
    type: {} as SignEcdsaLitActionParameters,
    schema: SignEcdsaLitActionSchema,
    descriptions: SignEcdsaLitActionParameterDescriptions,
    validate: validateSignEcdsaParameters,
  },
  policy: SignEcdsaPolicy,
});

/**
 * Export network-specific SendERC20 tools
 */
export const SignEcdsa = Object.entries(NETWORK_CONFIGS).reduce(
  (acc, [network, config]) => ({
    ...acc,
    [network]: createNetworkTool(network as SupportedLitNetwork, config),
  }),
  {} as Record<
    SupportedLitNetwork,
    FssTool<SignEcdsaLitActionParameters, SignEcdsaPolicyType>
  >
);
