// Modified ipfs.ts
import { join } from 'path';

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

function isNode(): boolean {
  return typeof process !== 'undefined' && 
         process.versions != null && 
         process.versions.node != null;
}

let deployedCids = DEFAULT_CIDS;

if (isNode()) {
  const { existsSync } = require('fs');
  const ipfsPath = join(__dirname, '../../../dist/ipfs.json');
  
  if (existsSync(ipfsPath)) {
    const ipfsJson = require(ipfsPath);
    deployedCids = ipfsJson;
  } else {
    console.warn('Failed to read ipfs.json. Using default CIDs.');
  }
}

export const IPFS_CIDS = deployedCids;