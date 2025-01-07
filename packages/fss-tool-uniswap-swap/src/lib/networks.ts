/**
 * Represents the configuration for a specific network in the ERC20Transfer tool.
 * @typedef {Object} NetworkConfig
 * @property {string} litNetwork - The Lit network identifier (e.g., 'datil-dev', 'datil-test', 'datil').
 * @property {string} ipfsCid - The IPFS CID (Content Identifier) associated with the network configuration.
 */

/**
 * Network-specific configurations for the ERC20Transfer tool.
 * @type {Record<string, NetworkConfig>}
 * @description A mapping of network names to their respective configurations.
 */
export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'datil-dev': {
    litNetwork: 'datil-dev', // Lit network identifier for the development environment
    ipfsCid: '', // IPFS CID for the development environment (to be populated if needed)
  },
  'datil-test': {
    litNetwork: 'datil-test', // Lit network identifier for the testing environment
    ipfsCid: '', // IPFS CID for the testing environment (to be populated if needed)
  },
  datil: {
    litNetwork: 'datil', // Lit network identifier for the production environment
    ipfsCid: '', // IPFS CID for the production environment (to be populated if needed)
  },
};
