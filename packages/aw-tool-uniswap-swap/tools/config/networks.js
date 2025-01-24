/**
 * Network configurations for building and deploying Lit Actions
 */
module.exports = {
  'datil-dev': {
    pkpToolRegistryAddress: '0xC69f619ec6dB158cec7511823afC9720b942005B',
    litNetwork: 'datil-dev',
    outputFiles: [
      'deployed-lit-action-datil-dev.js',
      'deployed-lit-action-policy-datil-dev.js',
    ],
  },
  'datil-test': {
    pkpToolRegistryAddress: '0xC1665Ba933250E9fB824b60d1B8df17336234973',
    litNetwork: 'datil-test',
    outputFiles: [
      'deployed-lit-action-datil-test.js',
      'deployed-lit-action-policy-datil-test.js',
    ],
  },
  datil: {
    pkpToolRegistryAddress: '0x6d70AAD76e1C9C279acCD3899D432daEAAC19CA3',
    litNetwork: 'datil',
    outputFiles: [
      'deployed-lit-action-datil.js',
      'deployed-lit-action-policy-datil.js',
    ],
  },
};
