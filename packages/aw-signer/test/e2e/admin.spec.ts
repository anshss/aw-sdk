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
  const POLICY_IPFS_CID = 'QmTestPolicyIpfsCid';
  const POLICY_1_ENABLED = true;
  //   const POLICY_2_ENABLED = false;

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

    it('should register a tool for PKP, but it should not be enabled', async () => {
      const { litContractsTxReceipt, toolRegistryContractTxReceipt } =
        await admin.registerTool(pkpTokenId, ERC20_TRANSFER_TOOL_IPFS_CID, {
          enableTools: false,
        });

      expect(litContractsTxReceipt).toBeDefined();
      expect(litContractsTxReceipt.status).toBe(1);

      expect(toolRegistryContractTxReceipt).toBeDefined();
      expect(toolRegistryContractTxReceipt.status).toBe(1);
    }, 60000);

    it('should get a registered tool by its IPFS CID for a given PKP', async () => {
      // Retrieve the registered tool
      const toolInfo = await admin.getRegisteredTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(toolInfo).toBeDefined();
      expect(toolInfo.toolIpfsCid).toBe(ERC20_TRANSFER_TOOL_IPFS_CID);
      expect(toolInfo.toolEnabled).toBe(false);
    }, 60000);

    it('should enable a registered tool for PKP', async () => {
      const txReceipt = await admin.enableTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );
      expect(txReceipt).toBeDefined();
      expect(txReceipt.status).toBe(1);
    }, 60000);

    it('should get enabled registered tool with no policy for PKP', async () => {
      const registeredTools = await admin.getRegisteredToolsAndDelegateesForPkp(
        pkpTokenId
      );

      expect(registeredTools).toBeDefined();
      expect(typeof registeredTools.toolsWithPolicies).toBe('object');
      expect(typeof registeredTools.toolsWithoutPolicies).toBe('object');
      expect(typeof registeredTools.toolsUnknownWithPolicies).toBe('object');
      expect(Array.isArray(registeredTools.toolsUnknownWithoutPolicies)).toBe(
        true
      );

      // Check if ERC20 Transfer tool is registered without policy
      const erc20Tool =
        registeredTools.toolsWithoutPolicies[ERC20_TRANSFER_TOOL_IPFS_CID];
      expect(erc20Tool).toBeDefined();
      expect(erc20Tool.name).toBe('ERC20Transfer');
      expect(erc20Tool.description).toBe(
        'A Lit Action that sends ERC-20 tokens.'
      );
      expect(erc20Tool.network).toBe('datil-test');
      expect(erc20Tool.toolEnabled).toBe(true);
    }, 60000);

    it('should add a delegatee for PKP', async () => {
      const txReceipt = await admin.addDelegatee(pkpTokenId, DELEGATEE_1);

      expect(txReceipt).toBeDefined();
      expect(txReceipt.status).toBe(1);

      // Verify that the delegatee was added
      const delegatees = await admin.getDelegatees(pkpTokenId);

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

    it('should retrieve the policy for a specific tool and delegatee', async () => {
      // Retrieve the tool policy for the delegatee
      const toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(null);
      expect(toolPolicy.enabled).toBe(false);
    }, 60000);

    it('should set the policy for a specific tool and delegatee', async () => {
      await admin.setToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        POLICY_IPFS_CID,
        POLICY_1_ENABLED
      );

      // Retrieve the tool policy for the delegatee
      const toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(POLICY_1_ENABLED);
    }, 60000);

    it('should get registered tool with policy for PKP', async () => {
      const registeredTools = await admin.getRegisteredToolsAndDelegateesForPkp(
        pkpTokenId
      );

      expect(registeredTools).toBeDefined();
      expect(typeof registeredTools.toolsWithPolicies).toBe('object');
      expect(typeof registeredTools.toolsWithoutPolicies).toBe('object');
      expect(typeof registeredTools.toolsUnknownWithPolicies).toBe('object');
      expect(Array.isArray(registeredTools.toolsUnknownWithoutPolicies)).toBe(
        true
      );

      // Check if ERC20 Transfer tool is registered with policy
      const erc20Tool =
        registeredTools.toolsWithPolicies[ERC20_TRANSFER_TOOL_IPFS_CID];
      expect(erc20Tool).toBeDefined();
      expect(erc20Tool.name).toBe('ERC20Transfer');
      expect(erc20Tool.description).toBe(
        'A Lit Action that sends ERC-20 tokens.'
      );
      expect(erc20Tool.network).toBe('datil-test');
      expect(erc20Tool.toolEnabled).toBe(true);
      expect(typeof erc20Tool.delegateePolicies).toBe('object');

      // Check the delegatee policy structure
      const delegateePolicy = erc20Tool.delegateePolicies[DELEGATEE_1];
      expect(delegateePolicy).toBeDefined();
      expect(delegateePolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(delegateePolicy.policyEnabled).toBe(POLICY_1_ENABLED);
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
