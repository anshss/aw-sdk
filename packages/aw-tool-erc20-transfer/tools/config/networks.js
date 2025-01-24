/**
 * Network configurations for building and deploying Lit Actions
 */
module.exports = {
  'datil-dev': {
    pkpToolRegistryAddress: '0x6D3Cfa27F0CEC501E0cf678Aa709eF18EcA7be6F',
    litNetwork: 'datil-dev',
    outputFiles: [
      'deployed-lit-action-datil-dev.js',
      'deployed-lit-action-policy-datil-dev.js',
    ],
  },
  'datil-test': {
    pkpToolRegistryAddress: '0xbac264BB694cdF98d7eed906DC89A2C98e0347b6',
    litNetwork: 'datil-test',
    outputFiles: [
      'deployed-lit-action-datil-test.js',
      'deployed-lit-action-policy-datil-test.js',
    ],
  },
  datil: {
    pkpToolRegistryAddress: '0x365772e35b30BcC975a7A4EE0691e87aa055013E',
    litNetwork: 'datil',
    outputFiles: [
      'deployed-lit-action-datil.js',
      'deployed-lit-action-policy-datil.js',
    ],
  },
};
