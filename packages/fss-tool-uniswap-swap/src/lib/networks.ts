/**
 * Represents the network-specific configuration for the ERC20Transfer tool.
 * @property {string} litNetwork - The name of the Lit network.
 * @property {string} ipfsCid - The IPFS CID for the Lit Action on this network.
 */
export interface NetworkConfig {
  litNetwork: string;
  ipfsCid: string;
}

/**
 * A collection of network-specific configurations for the ERC20Transfer tool.
 * Each key represents a supported network, and the value contains the configuration for that network.
 * @type {Record<string, NetworkConfig>}
 */
export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'datil-dev': {
    litNetwork: 'datil-dev',
    ipfsCid: '', // IPFS CID for the development network
  },
  'datil-test': {
    litNetwork: 'datil-test',
    ipfsCid: '', // IPFS CID for the test network
  },
  datil: {
    litNetwork: 'datil',
    ipfsCid: '', // IPFS CID for the production network
  },
};
