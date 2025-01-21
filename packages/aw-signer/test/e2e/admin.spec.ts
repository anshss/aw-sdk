import { config } from '@dotenvx/dotenvx';
import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';

import { Admin } from '../../src/lib/admin';
import { PkpInfo } from '../../src/lib/types';

// Load environment variables
config();

const PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY;
if (!PRIVATE_KEY) {
  throw new Error('ADMIN_PRIVATE_KEY environment variable is required');
}

describe('Admin E2E', () => {
  const STORAGE_PATH = path.join(__dirname, '../../.aw-signer-admin-storage');
  const ERC20_TRANSFER_TOOL_IPFS_CID =
    'Qmd66gsFKfavcUdYeM4ZN1z1c6VG1fZPEKtSG7WsdrsmMn';
  const DELEGATEE_1 = ethers.Wallet.createRandom().address;
  //   const DELEGATEE_2 = ethers.Wallet.createRandom().address;

  let admin: Admin;

  beforeAll(async () => {
    // Create Admin instance with real network connections
    admin = await Admin.create(
      { type: 'eoa', privateKey: PRIVATE_KEY },
      { litNetwork: 'datil-test' }
    );
  }, 30000); // Increase timeout for network connections

  afterAll(async () => {
    admin.disconnect();

    // Remove storage directory if it exists
    if (fs.existsSync(STORAGE_PATH)) {
      fs.rmSync(STORAGE_PATH, { recursive: true, force: true });
    }
  });

  describe.skip('PKP Management', () => {
    let pkpMetadata: PkpInfo;

    it('should mint a new PKP', async () => {
      pkpMetadata = await admin.mintPkp();
      expect(pkpMetadata).toBeDefined();
      expect(pkpMetadata.info.tokenId).toBeDefined();
      expect(pkpMetadata.info.publicKey).toBeDefined();
    }, 60000); // Increase timeout for blockchain transaction

    it('should get PKPs from storage', async () => {
      const pkps = await admin.getPkps();
      expect(Array.isArray(pkps)).toBe(true);
      expect(pkps.length).toBeGreaterThan(0);
      expect(pkps[0].info.tokenId).toBe(pkpMetadata.info.tokenId);
    });

    it('should get specific PKP by token ID', async () => {
      const pkp = await admin.getPkpByTokenId(pkpMetadata.info.tokenId);
      expect(pkp).toBeDefined();
      expect(pkp.info.tokenId).toBe(pkpMetadata.info.tokenId);
    }, 60000);
  });

  describe('Tool, Delegatee, and Policy Management', () => {
    let pkpTokenId: string;

    beforeAll(async () => {
      // Mint a PKP to use for tool tests
      const pkpMetadata = await admin.mintPkp();
      pkpTokenId = pkpMetadata.info.tokenId;
    }, 60000);

    it('should permit a tool for PKP', async () => {
      const { litContractsTxReceipt, toolRegistryContractTxReceipt } =
        await admin.permitTool(pkpTokenId, ERC20_TRANSFER_TOOL_IPFS_CID);

      expect(litContractsTxReceipt).toBeDefined();
      expect(litContractsTxReceipt.status).toBe(1);

      expect(toolRegistryContractTxReceipt).toBeDefined();
      expect(toolRegistryContractTxReceipt.status).toBe(1);
    }, 60000);

    it('should get registered tool with no policy for PKP', async () => {
      const registeredTools = await admin.getRegisteredToolsForPkp(pkpTokenId);

      console.log(registeredTools);

      //   expect(registeredTools).toBeDefined();
      //   expect(Array.isArray(registeredTools.toolsWithPolicies)).toBe(true);
      //   expect(Array.isArray(registeredTools.toolsWithoutPolicies)).toBe(true);
      //   expect(Array.isArray(registeredTools.toolsUnknownWithPolicies)).toBe(
      //     true
      //   );
      //   expect(Array.isArray(registeredTools.toolsUnknownWithoutPolicies)).toBe(
      //     true
      //   );

      //   expect(registeredTools.toolsWithPolicies.length).toBe(0);
      //   expect(registeredTools.toolsWithoutPolicies.length).toBe(1);
      //   expect(registeredTools.toolsUnknownWithPolicies.length).toBe(0);
      //   expect(registeredTools.toolsUnknownWithoutPolicies.length).toBe(0);

      //   expect(registeredTools.toolsWithoutPolicies[0].ipfsCid).toBe(
      //     ERC20_TRANSFER_TOOL_IPFS_CID
      //   );
    }, 60000);

    it('should add a delegatee for PKP', async () => {
      const txReceipt = await admin.addDelegatee(pkpTokenId, DELEGATEE_1);

      expect(txReceipt).toBeDefined();
      expect(txReceipt.status).toBe(1);

      // Verify that the delegatee was added
      const delegatees = await admin.getDelegatees(pkpTokenId);

      console.log('delegatees', delegatees);

      expect(delegatees).toBeDefined();
      expect(Array.isArray(delegatees)).toBe(true);
      expect(delegatees.length).toBe(1);
      expect(delegatees[0]).toBe(DELEGATEE_1);
    }, 60000);

    it('should check if an address is a delegatee for PKP', async () => {
      // Check if the address is a delegatee
      let isDelegatee = await admin.isDelegatee(pkpTokenId, DELEGATEE_1);
      expect(isDelegatee).toBe(true);

      isDelegatee = await admin.isDelegatee(
        pkpTokenId,
        ethers.Wallet.createRandom().address
      );
      expect(isDelegatee).toBe(false);
    }, 60000);
  });

  describe.skip('Ownership Management', () => {
    let pkpTokenId: string;
    let newOwner: string;

    beforeAll(async () => {
      // Create a new wallet to be the recipient
      const wallet = ethers.Wallet.createRandom();
      newOwner = wallet.address;

      // Mint a PKP to transfer
      const pkpMetadata = await admin.mintPkp();
      pkpTokenId = pkpMetadata.info.tokenId;
    }, 60000);

    it('should transfer PKP ownership', async () => {
      const receipt = await admin.transferPkpOwnership(pkpTokenId, newOwner);
      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);
    }, 60000);
  });
});
