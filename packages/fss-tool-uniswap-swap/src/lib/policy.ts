import { BaseEthereumAddressSchema } from '@lit-protocol/fss-tool';
import { z } from 'zod';
import { ethers } from 'ethers';

/**
 * Schema for validating a UniswapSwap policy.
 * @type {z.ZodObject}
 * @property {z.ZodLiteral<'UniswapSwap'>} type - The type of the policy, must be 'UniswapSwap'.
 * @property {z.ZodString} version - The version of the policy.
 * @property {z.ZodString} maxAmount - The maximum allowed amount for the swap, must be a non-negative integer.
 * @property {z.ZodArray<BaseEthereumAddressSchema>} allowedTokens - An array of allowed token addresses.
 */
const policySchema = z.object({
  type: z.literal('UniswapSwap'), // Policy type, must be 'UniswapSwap'
  version: z.string(), // Policy version
  maxAmount: z.string().refine(
    (val) => {
      try {
        const bn = ethers.BigNumber.from(val);
        return !bn.isNegative(); // Ensure the amount is non-negative
      } catch {
        return false; // Handle invalid format
      }
    },
    { message: 'Invalid amount format. Must be a non-negative integer.' }
  ),
  allowedTokens: z.array(BaseEthereumAddressSchema), // Array of allowed token addresses
});

/**
 * Encodes a UniswapSwap policy into a ABI-encoded string.
 * @param {UniswapSwapPolicyType} policy - The policy object to encode.
 * @returns {string} The ABI-encoded policy string.
 */
function encodePolicy(policy: UniswapSwapPolicyType): string {
  policySchema.parse(policy); // Validate the policy against the schema

  return ethers.utils.defaultAbiCoder.encode(
    ['tuple(uint256 maxAmount, address[] allowedTokens)'], // ABI encoding schema
    [
      {
        maxAmount: policy.maxAmount, // Encode maxAmount
        allowedTokens: policy.allowedTokens, // Encode allowedTokens
      },
    ]
  );
}

/**
 * Decodes an ABI-encoded UniswapSwap policy string into a policy object.
 * @param {string} encodedPolicy - The ABI-encoded policy string.
 * @returns {UniswapSwapPolicyType} The decoded policy object.
 */
function decodePolicy(encodedPolicy: string): UniswapSwapPolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ['tuple(uint256 maxAmount, address[] allowedTokens)'], // ABI decoding schema
    encodedPolicy
  )[0];

  const policy: UniswapSwapPolicyType = {
    type: 'UniswapSwap', // Policy type
    version: '1.0.0', // Policy version
    maxAmount: decoded.maxAmount.toString(), // Decoded maxAmount
    allowedTokens: decoded.allowedTokens, // Decoded allowedTokens
  };

  return policySchema.parse(policy); // Validate and return the decoded policy
}

/**
 * Type representing a UniswapSwap policy.
 * @typedef {z.infer<typeof policySchema>} UniswapSwapPolicyType
 */
export type UniswapSwapPolicyType = z.infer<typeof policySchema>;

/**
 * Utility object for working with UniswapSwap policies.
 * @type {Object}
 * @property {UniswapSwapPolicyType} type - Placeholder for the policy type.
 * @property {string} version - The version of the policy utility.
 * @property {z.ZodObject} schema - The Zod schema for validating policies.
 * @property {Function} encode - Function to encode a policy into an ABI-encoded string.
 * @property {Function} decode - Function to decode an ABI-encoded string into a policy object.
 */
export const UniswapSwapPolicy = {
  type: {} as UniswapSwapPolicyType, // Placeholder for the policy type
  version: '1.0.0', // Version of the policy utility
  schema: policySchema, // Zod schema for validation
  encode: encodePolicy, // Encoding function
  decode: decodePolicy, // Decoding function
};
