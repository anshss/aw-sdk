/**
 * Network-specific configuration for the SendERC20 tool
 */
export interface NetworkConfig {
  pubkeyRouterAddress: string;
  litNetwork: string;
  ipfsCid: string;
}

/**
 * Network-specific configurations
 */
export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'datil-dev': {
    pubkeyRouterAddress: '0x...', // Replace with actual address
    litNetwork: 'datil-dev',
    ipfsCid: '...', // Replace with actual IPFS CID for datil-dev
  },
  'datil-test': {
    pubkeyRouterAddress: '0x...', // Replace with actual address
    litNetwork: 'datil-test',
    ipfsCid: '...', // Replace with actual IPFS CID for datil-test
  },
  datil: {
    pubkeyRouterAddress: '0x...', // Replace with actual address
    litNetwork: 'datil',
    ipfsCid: '...', // Replace with actual IPFS CID for datil
  },
};
