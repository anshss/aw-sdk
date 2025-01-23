import { z } from 'zod';
import { LIT_NETWORK } from '@lit-protocol/constants';

/**
 * Represents the supported Lit networks for the tool.
 * @typedef {string} SupportedLitNetwork
 * @description Can be one of the following:
 * - `LIT_NETWORK.DatilDev` (development environment)
 * - `LIT_NETWORK.DatilTest` (testing environment)
 * - `LIT_NETWORK.Datil` (production environment)
 */
export type SupportedLitNetwork =
  | (typeof LIT_NETWORK)['DatilDev']
  | (typeof LIT_NETWORK)['DatilTest']
  | (typeof LIT_NETWORK)['Datil'];

/**
 * Represents the configuration for a specific Lit network.
 * @typedef {Object} NetworkConfig
 * @property {string} litNetwork - The Lit network identifier (e.g., 'datil-dev', 'datil-test', 'datil').
 * @property {string} ipfsCid - The IPFS CID (Content Identifier) associated with the network configuration.
 * @property {string} defaultPolicyIpfsCid - The IPFS CID (Content Identifier) associated with the network's default policy. Populate if needed.
 */
export interface NetworkConfig {
  litNetwork: string;
  ipfsCid: string;
  defaultPolicyIpfsCid: string;
}

/**
 * Network-specific configurations for the Tool.
 * @type {Record<string, NetworkConfig>}
 * @description A mapping of network names to their respective configurations.
 */
export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'datil-dev': {
    litNetwork: 'datil-dev', // Lit network identifier for the development environment
    ipfsCid: '', // IPFS CID for the development environment (to be populated if needed)
    defaultPolicyIpfsCid: '', // IPFS CID for the development environment's default policy (to be populated if needed)
  },
  'datil-test': {
    litNetwork: 'datil-test', // Lit network identifier for the testing environment
    ipfsCid: '', // IPFS CID for the testing environment (to be populated if needed)
    defaultPolicyIpfsCid: '', // IPFS CID for the testing environment's default policy (to be populated if needed)
  },
  datil: {
    litNetwork: 'datil', // Lit network identifier for the production environment
    ipfsCid: '', // IPFS CID for the production environment (to be populated if needed)
    defaultPolicyIpfsCid: '', // IPFS CID for the production environment's default policy (to be populated if needed)
  },
};

/**
 * Zod schema for validating Ethereum addresses.
 * @type {z.ZodString}
 * @description Ensures the address is a valid Ethereum address (0x followed by 40 hexadecimal characters).
 */
export const BaseEthereumAddressSchema = z
  .string()
  .regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum address format');

/**
 * Represents a validated Ethereum address.
 * @typedef {z.infer<typeof BaseEthereumAddressSchema>} EthereumAddress
 */
export type EthereumAddress = z.infer<typeof BaseEthereumAddressSchema>;

/**
 * Represents a generic AW (Function-as-a-Service) tool.
 * @template TParams - The type of the tool's parameters.
 * @template TPolicy - The type of the tool's policy.
 */
export interface AwTool<
  TParams extends Record<string, any> = Record<string, any>,
  TPolicy extends { type: string } = { type: string }
> {
  /**
   * The name of the tool. This should be a unique identifier that clearly describes the tool's purpose.
   */
  name: string;

  /**
   * A detailed description of the tool's functionality, including its purpose, use cases, and any important notes.
   */
  description: string;

  /**
   * The IPFS Content Identifier (CID) that points to the tool's Lit Action implementation.
   * This is used to locate and execute the tool's code.
   */
  ipfsCid: string;

  /**
   * The IPFS Content Identifier (CID) that points to the tool's default policy configuration.
   * This policy is used when no custom policy is specified for the tool.
   */
  defaultPolicyIpfsCid: string;

  /**
   * Configuration for the tool's parameters.
   * Defines the structure, validation, and documentation of the tool's input parameters.
   */
  parameters: {
    /**
     * The TypeScript type definition for the tool's parameters.
     * This serves as a compile-time type check for parameter values.
     */
    type: TParams;

    /**
     * Zod schema for runtime validation of parameter values.
     * Ensures that parameters meet the required format and constraints.
     */
    schema: z.ZodType<TParams>;

    /**
     * Human-readable descriptions of each parameter.
     * Provides documentation about what each parameter does and how it should be used.
     */
    descriptions: Readonly<Record<keyof TParams, string>>;

    /**
     * Function to validate parameter values at runtime.
     * @param params - The parameters to validate.
     * @returns true if validation succeeds, or an array of validation errors if it fails.
     */
    validate: (
      params: unknown
    ) => true | Array<{ param: string; error: string }>;
  };

  /**
   * Configuration for the tool's policy.
   * Defines how the tool's execution policies are structured, validated, and encoded.
   */
  policy: {
    /**
     * The TypeScript type definition for the tool's policy.
     * This serves as a compile-time type check for policy values.
     */
    type: TPolicy;

    /**
     * The version string for the policy format.
     * Used to track policy compatibility and handle upgrades.
     */
    version: string;

    /**
     * Zod schema for runtime validation of policy values.
     * Ensures that policies meet the required format and constraints.
     */
    schema: z.ZodType<TPolicy>;

    /**
     * Function to encode a policy object into a string format for storage or transmission.
     * @param policy - The policy object to encode.
     * @returns The encoded policy string.
     */
    encode: (policy: TPolicy) => string;

    /**
     * Function to decode a policy string back into a policy object.
     * @param encodedPolicy - The encoded policy string to decode.
     * @returns The decoded policy object.
     */
    decode: (encodedPolicy: string) => TPolicy;
  };
}
