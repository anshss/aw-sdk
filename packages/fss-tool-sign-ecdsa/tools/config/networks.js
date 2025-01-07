/**
 * Network configurations for building and deploying Lit Actions
 */
module.exports = {
  'datil-dev': {
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil-dev',
    outputFile: 'deployed-lit-action-datil-dev.js',
  },
  'datil-test': {
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil-test',
    outputFile: 'deployed-lit-action-datil-test.js',
  },
  datil: {
    pkpToolRegistryAddress: '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F',
    litNetwork: 'datil',
    outputFile: 'deployed-lit-action-datil.js',
  },
};
