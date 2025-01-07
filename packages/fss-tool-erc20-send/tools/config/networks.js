/**
 * Network configurations for building and deploying Lit Actions
 */
module.exports = {
  'datil-dev': {
    pubkeyRouterAddress: '0xbc01f21C58Ca83f25b09338401D53D4c2344D1d9',
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil-dev',
    outputFile: 'deployed-lit-action-datil-dev.js',
  },
  'datil-test': {
    pubkeyRouterAddress: '0x65C3d057aef28175AfaC61a74cc6b27E88405583',
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil-test',
    outputFile: 'deployed-lit-action-datil-test.js',
  },
  datil: {
    pubkeyRouterAddress: '0xF182d6bEf16Ba77e69372dD096D8B70Bc3d5B475',
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil',
    outputFile: 'deployed-lit-action-datil.js',
  },
};
