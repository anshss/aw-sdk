import { existsSync } from 'fs';
import { join } from 'path';

// Default development CIDs
const DEFAULT_CIDS = {
  'datil-dev': 'DEV_IPFS_CID',
  'datil-test': 'TEST_IPFS_CID',
  datil: 'PROD_IPFS_CID',
} as const;

// Try to read the IPFS CIDs from the build output
let deployedCids: Record<keyof typeof DEFAULT_CIDS, string> = DEFAULT_CIDS;

try {
  const ipfsPath = join(__dirname, '../../../dist/ipfs.json');
  if (existsSync(ipfsPath)) {
    // We know this import will work because we checked the file exists
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const ipfsJson = require(ipfsPath);
    deployedCids = ipfsJson;
  } else {
    console.warn(
      'ipfs.json not found. Using development CIDs. Please run deploy script to update.'
    );
  }
} catch (error) {
  console.warn(
    'Failed to read ipfs.json. Using development CIDs:',
    error instanceof Error ? error.message : String(error)
  );
}

/**
 * IPFS CIDs for each network's Lit Action
 */
export const IPFS_CIDS = deployedCids;
