import { z } from 'zod';
import {
  type FssTool,
  type SupportedLitNetwork,
  NETWORK_CONFIGS,
  NetworkConfig,
} from '@lit-protocol/fss-tool';

import { ERC20TransferPolicy, type ERC20TransferPolicyType } from './policy';
import { IPFS_CIDS } from './ipfs';

/**
 * Parameters required for the ERC20 Send Lit Action
 * @property pkpEthAddress - The Ethereum address of the PKP
 * @property tokenIn - The ERC20 token contract address to send
 * @property recipientAddress - The Ethereum address to receive the tokens
 * @property amountIn - The amount of tokens to send as a string (will be parsed based on token decimals)
 * @property chainId - The ID of the blockchain network
 * @property rpcUrl - The RPC URL of the blockchain network
 */
interface ERC20TransferLitActionParameters {
  pkpEthAddress: string;
  tokenIn: string;
  recipientAddress: string;
  amountIn: string;
  chainId: string;
  rpcUrl: string;
}

/**
 * Zod schema for validating ERC20TransferLitActionParameters
 */
const ERC20TransferLitActionSchema = z.object({
  pkpEthAddress: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum address (0x followed by 40 hexadecimal characters)'
    ),
  tokenIn: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum contract address (0x followed by 40 hexadecimal characters)'
    ),
  recipientAddress: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum address (0x followed by 40 hexadecimal characters)'
    ),
  amountIn: z
    .string()
    .regex(
      /^\d*\.?\d+$/,
      'Must be a valid decimal number as a string (e.g. "1.5" or "100")'
    ),
  chainId: z
    .string()
    .regex(/^\d+$/, 'Must be a valid chain ID number as a string'),
  rpcUrl: z
    .string()
    .url()
    .startsWith(
      'https://',
      'Must be a valid HTTPS URL for the blockchain RPC endpoint'
    ),
});

/**
 * Descriptions of each parameter for the ERC20 Send Lit Action
 * These descriptions are designed to be consumed by LLMs to understand the required parameters
 */
const ERC20TransferLitActionParameterDescriptions = {
  pkpEthAddress:
    'The Ethereum address of the PKP that will be used to sign and send the transaction.',
  tokenIn:
    'The Ethereum contract address of the ERC20 token you want to send. Must be a valid Ethereum address starting with 0x.',
  recipientAddress:
    'The Ethereum wallet address of the recipient who will receive the tokens. Must be a valid Ethereum address starting with 0x.',
  amountIn:
    'The amount of tokens to send, specified as a string. This should be a decimal number (e.g. "1.5" or "100"). The amount will be automatically adjusted based on the token\'s decimals.',
  chainId:
    'The ID of the blockchain network to send the tokens on (e.g. 1 for Ethereum mainnet, 84532 for Base Sepolia).',
  rpcUrl:
    'The RPC URL of the blockchain network to connect to (e.g. "https://base-sepolia-rpc.publicnode.com").',
} as const;

/**
 * Validate parameters and return detailed error messages if invalid
 */
const validateERC20TransferParameters = (
  params: unknown
): true | Array<{ param: string; error: string }> => {
  const result = ERC20TransferLitActionSchema.safeParse(params);
  if (result.success) {
    return true;
  }

  return result.error.issues.map((issue) => ({
    param: issue.path[0] as string,
    error: issue.message,
  }));
};

/**
 * Create a network-specific ERC20Transfer tool
 */
const createNetworkTool = (
  network: SupportedLitNetwork,
  config: NetworkConfig
): FssTool<ERC20TransferLitActionParameters, ERC20TransferPolicyType> => ({
  name: 'ERC20Transfer',
  description: `A Lit Action that sends ERC-20 tokens, using the ${config.litNetwork} network for signing.`,
  ipfsCid: IPFS_CIDS[network],
  parameters: {
    type: {} as ERC20TransferLitActionParameters,
    schema: ERC20TransferLitActionSchema,
    descriptions: ERC20TransferLitActionParameterDescriptions,
    validate: validateERC20TransferParameters,
  },
  policy: ERC20TransferPolicy,
});

/**
 * Export network-specific ERC20Transfer tools
 */
export const ERC20Transfer = Object.entries(NETWORK_CONFIGS).reduce(
  (acc, [network, config]) => ({
    ...acc,
    [network]: createNetworkTool(network as SupportedLitNetwork, config),
  }),
  {} as Record<
    SupportedLitNetwork,
    FssTool<ERC20TransferLitActionParameters, ERC20TransferPolicyType>
  >
);
