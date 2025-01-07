/**
 * Network-specific configuration for the ERC20Transfer tool
 */
export interface NetworkConfig {
  litNetwork: string;
  ipfsCid: string;
}

/**
 * Network-specific configurations
 */
export const NETWORK_CONFIGS: Record<string, NetworkConfig> = {
  'datil-dev': {
    litNetwork: 'datil-dev',
    ipfsCid: '',
  },
  'datil-test': {
    litNetwork: 'datil-test',
    ipfsCid: '',
  },
  datil: {
    litNetwork: 'datil',
    ipfsCid: '',
  },
};
