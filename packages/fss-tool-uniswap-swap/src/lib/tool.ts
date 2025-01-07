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
 * Parameters required for the Swap Uniswap Lit Action.
 * @property {string} tokenIn - The ERC20 token contract address to send.
 * @property {string} tokenOut - The ERC20 token contract address to receive.
 * @property {string} amountIn - The amount of tokens to send as a string (will be parsed based on token decimals).
 * @property {string} chainId - The ID of the blockchain network.
 * @property {string} rpcUrl - The RPC URL of the blockchain network.
 */
export interface UniswapSwapLitActionParameters {
  tokenIn: string;
  tokenOut: string;
  amountIn: string;
  chainId: string;
  rpcUrl: string;
}

/**
 * Zod schema for validating UniswapSwapLitActionParameters.
 * @type {z.ZodObject}
 */
const UniswapSwapLitActionSchema = z.object({
  tokenIn: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum contract address (0x followed by 40 hexadecimal characters)'
    ), // Validates Ethereum contract address format
  tokenOut: z
    .string()
    .regex(
      /^0x[a-fA-F0-9]{40}$/,
      'Must be a valid Ethereum contract address (0x followed by 40 hexadecimal characters)'
    ), // Validates Ethereum contract address format
  amountIn: z
    .string()
    .regex(
      /^\d*\.?\d+$/,
      'Must be a valid decimal number as a string (e.g. "1.5" or "100")'
    ), // Validates decimal number format
  chainId: z
    .string()
    .regex(/^\d+$/, 'Must be a valid chain ID number as a string'), // Validates chain ID format
  rpcUrl: z
    .string()
    .url()
    .startsWith(
      'https://',
      'Must be a valid HTTPS URL for the blockchain RPC endpoint'
    ), // Validates HTTPS URL format
});

/**
 * Descriptions of each parameter for the Swap Uniswap Lit Action.
 * These descriptions are designed to be consumed by LLMs to understand the required parameters.
 * @type {Object}
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
 * Validates parameters and returns detailed error messages if invalid.
 * @param {unknown} params - The parameters to validate.
 * @returns {true | Array<{ param: string; error: string }>} - Returns `true` if valid, or an array of errors if invalid.
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
 * Creates a network-specific UniswapSwap tool.
 * @param {SupportedLitNetwork} network - The Lit network to configure the tool for.
 * @param {NetworkConfig} config - The network configuration.
 * @returns {FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType>} - The configured UniswapSwap tool.
 */
const createNetworkTool = (
  network: SupportedLitNetwork,
  config: NetworkConfig
): FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType> => ({
  name: 'UniswapSwap', // Name of the tool
  description: `A Lit Action that swaps tokens on Uniswap, using the ${config.litNetwork} network for signing.`, // Description of the tool
  ipfsCid: IPFS_CIDS[network], // IPFS CID for the Lit Action
  parameters: {
    type: {} as UniswapSwapLitActionParameters, // Placeholder for parameter type
    schema: UniswapSwapLitActionSchema, // Zod schema for parameter validation
    descriptions: UniswapSwapLitActionParameterDescriptions, // Descriptions of parameters
    validate: validateUniswapSwapParameters, // Validation function
  },
  policy: UniswapSwapPolicy, // Policy utility for encoding/decoding policies
});

/**
 * Exports network-specific UniswapSwap tools.
 * @type {Record<SupportedLitNetwork, FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType>>}
 */
export const UniswapSwap = Object.entries(NETWORK_CONFIGS).reduce(
  (acc, [network, config]) => ({
    ...acc,
    [network]: createNetworkTool(network as SupportedLitNetwork, config), // Create a tool for each network
  }),
  {} as Record<
    SupportedLitNetwork,
    FssTool<UniswapSwapLitActionParameters, UniswapSwapPolicyType>
  >
);
