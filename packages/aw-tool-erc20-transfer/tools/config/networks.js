/**
 * Network configurations for building and deploying Lit Actions
 */
module.exports = {
  'datil-dev': {
    pkpToolRegistryAddress: '0xad6123D29B470408bc536aA29d2233c8353a485e',
    litNetwork: 'datil-dev',
    outputFile: 'deployed-lit-action-datil-dev.js',
  },
  'datil-test': {
    pkpToolRegistryAddress: '0x2f02090138e29a7d345993b85D665B4377Fb22b0',
    litNetwork: 'datil-test',
    outputFile: 'deployed-lit-action-datil-test.js',
  },
  datil: {
    pkpToolRegistryAddress: '0xB41D75c11B557C1Df109940593c8cA75B2dd465c',
    litNetwork: 'datil',
    outputFile: 'deployed-lit-action-datil.js',
  },
};
