import { z } from 'zod';
import {
  type FssTool,
  type SupportedLitNetwork,
  NETWORK_CONFIGS,
  NetworkConfig,
} from '@lit-protocol/fss-tool';

import { UniswapSwapPolicy, type UniswapSwapPolicyType } from './policy';
import { IPFS_CIDS } from './ipfs';

/**
 * Parameters required for the Swap Uniswap Lit Action
 * @property tokenIn - The ERC20 token contract address to send
 * @property tokenOut - The ERC20 token contract address to receive
 * @property amountIn - The amount of tokens to send as a string (will be parsed based on token decimals)
 * @property chainId - The ID of the blockchain network
 * @property rpcUrl - The RPC URL of the blockchain network
 */
export interface UniswapSwapLitActionParameters {
  tokenIn: string;
  tokenOut: string;
  amountIn: string;
  chainId: string;
  rpcUrl: string;
}

/**
 * Zod schema for validating UniswapSwapLitActionParameters
 */
const UniswapSwapLitActionSchema = z.object({
  tokenIn: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum contract address (0x followed by 40 hexadecimal characters)'
    ),
  tokenOut: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum contract address (0x followed by 40 hexadecimal characters)'
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
 * Descriptions of each parameter for the Swap Uniswap Lit Action
 * These descriptions are designed to be consumed by LLMs to understand the required parameters
 */
const UniswapSwapLitActionParameterDescriptions = {
  tokenIn:
    'The Ethereum contract address of the ERC20 token you want to send. Must be a valid Ethereum address starting with 0x.',
  tokenOut:
    'The Ethereum contract address of the ERC20 token you want to receive. Must be a valid Ethereum address starting with 0x.',
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
const validateUniswapSwapParameters = (
  params: unknown
): true | Array<{ param: string; error: string }> => {
  const result = UniswapSwapLitActionSchema.safeParse(params);
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
): FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType> => ({
  name: 'UniswapSwap',
  description: `A Lit Action that swaps tokens on Uniswap.`,
  ipfsCid: IPFS_CIDS[network],
  parameters: {
    type: {} as UniswapSwapLitActionParameters,
    schema: UniswapSwapLitActionSchema,
    descriptions: UniswapSwapLitActionParameterDescriptions,
    validate: validateUniswapSwapParameters,
  },
  policy: UniswapSwapPolicy,
});

/**
 * Export network-specific ERC20Transfer tools
 */
export const UniswapSwap = Object.entries(NETWORK_CONFIGS).reduce(
  (acc, [network, config]) => ({
    ...acc,
    [network]: createNetworkTool(network as SupportedLitNetwork, config),
  }),
  {} as Record<
    SupportedLitNetwork,
    FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType>
  >
);