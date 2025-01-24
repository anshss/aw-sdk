/**
 * Configuration mapping for PubkeyRouter contract addresses across different Lit networks.
 * This constant provides the correct contract addresses for each supported network environment.
 * 
 * @property datil-dev - Development network configuration with PubkeyRouter address
 * @property datil-test - Test network configuration with PubkeyRouter address
 * @property datil - Production network configuration with PubkeyRouter address
 */
// Network to PubkeyRouter address mapping
export const NETWORK_CONFIG = {
  'datil-dev': {
    pubkeyRouterAddress: '0xbc01f21C58Ca83f25b09338401D53D4c2344D1d9',
  },
  'datil-test': {
    pubkeyRouterAddress: '0x65C3d057aef28175AfaC61a74cc6b27E88405583',
  },
  datil: {
    pubkeyRouterAddress: '0xF182d6bEf16Ba77e69372dD096D8B70Bc3d5B475',
  },
} as const;
