import { BaseEthereumAddressSchema } from '@lit-protocol/fss-tool';
import { z } from 'zod';
import { ethers } from 'ethers';

/**
 * Schema for validating an ERC20 transfer policy.
 * Ensures the policy has the correct structure and valid values.
 */
const policySchema = z.object({
  /** The type of policy, must be `ERC20Transfer`. */
  type: z.literal('ERC20Transfer'),

  /** The version of the policy. */
  version: z.string(),

  /** The maximum allowed transfer amount. Must be a non-negative integer. */
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

  /** An array of allowed token addresses. */
  allowedTokens: z.array(BaseEthereumAddressSchema),

  /** An array of allowed recipient addresses. */
  allowedRecipients: z.array(BaseEthereumAddressSchema),
});

/**
 * Encodes an ERC20 transfer policy into a format suitable for on-chain storage.
 * @param policy - The ERC20 transfer policy to encode.
 * @returns The encoded policy as a hex string.
 * @throws If the policy does not conform to the schema.
 */
function encodePolicy(policy: ERC20TransferPolicyType): string {
  // Validate the policy against the schema
  policySchema.parse(policy);

  // Encode the policy using ABI encoding
  return ethers.utils.defaultAbiCoder.encode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    [
      {
        maxAmount: policy.maxAmount,
        allowedTokens: policy.allowedTokens,
        allowedRecipients: policy.allowedRecipients,
      },
    ]
  );
}

/**
 * Decodes an ERC20 transfer policy from its on-chain encoded format.
 * @param encodedPolicy - The encoded policy as a hex string.
 * @returns The decoded ERC20 transfer policy.
 * @throws If the encoded policy is invalid or does not conform to the schema.
 */
function decodePolicy(encodedPolicy: string): ERC20TransferPolicyType {
  // Decode the policy using ABI decoding
  const decoded = ethers.utils.defaultAbiCoder.decode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    encodedPolicy
  )[0];

  // Construct the policy object
  const policy: ERC20TransferPolicyType = {
    type: 'ERC20Transfer',
    version: '1.0.0',
    maxAmount: decoded.maxAmount.toString(),
    allowedTokens: decoded.allowedTokens,
    allowedRecipients: decoded.allowedRecipients,
  };

  // Validate the decoded policy against the schema
  return policySchema.parse(policy);
}

/**
 * Represents the type of an ERC20 transfer policy, inferred from the schema.
 */
export type ERC20TransferPolicyType = z.infer<typeof policySchema>;

/**
 * Utility object for working with ERC20 transfer policies.
 * Includes the schema, encoding, and decoding functions.
 */
export const ERC20TransferPolicy = {
  /** The type of the policy. */
  type: {} as ERC20TransferPolicyType,

  /** The version of the policy. */
  version: '1.0.0',

  /** The schema for validating ERC20 transfer policies. */
  schema: policySchema,

  /** Encodes an ERC20 transfer policy into a format suitable for on-chain storage. */
  encode: encodePolicy,

  /** Decodes an ERC20 transfer policy from its on-chain encoded format. */
  decode: decodePolicy,
};

function decodePolicy(encodedPolicy: string): ERC20TransferPolicyType {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    [
      'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
    ],
    encodedPolicy
  )[0];

  const policy: ERC20TransferPolicyType = {
    type: 'ERC20Transfer',
    version: '1.0.0',
    maxAmount: decoded.maxAmount.toString(),
    allowedTokens: decoded.allowedTokens,
    allowedRecipients: decoded.allowedRecipients,
  };

  return policySchema.parse(policy);
}

export type ERC20TransferPolicyType = z.infer<typeof policySchema>;

export const ERC20TransferPolicy = {
  type: {} as ERC20TransferPolicyType,
  version: '1.0.0',
  schema: policySchema,
  encode: encodePolicy,
  decode: decodePolicy,
};
