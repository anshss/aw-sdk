const DEFAULT_CIDS = {
  'datil-dev': {
    tool: 'DEV_TOOL_IPFS_CID',
    defaultPolicy: 'DEV_POLICY_IPFS_CID',
  },
  'datil-test': {
    tool: 'TEST_TOOL_IPFS_CID',
    defaultPolicy: 'TEST_POLICY_IPFS_CID',
  },
  datil: {
    tool: 'PROD_TOOL_IPFS_CID',
    defaultPolicy: 'PROD_POLICY_IPFS_CID',
  },
} as const;

let deployedCids = DEFAULT_CIDS;

function isNode(): boolean {
  return typeof process !== 'undefined' && 
         process.versions != null && 
         process.versions.node != null;
}

if (isNode()) {
  try {
    const path = require('path');
    const fs = require('fs');
    const url = require('url');
    
    const __filename = url.fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const ipfsPath = path.join(__dirname, '../../../dist/ipfs.json');
    
    if (fs.existsSync(ipfsPath)) {
      deployedCids = require(ipfsPath);
    }
  } catch (error) {
    console.warn('Failed to load IPFS config, using defaults');
  }
}

export const IPFS_CIDS = deployedCids;
