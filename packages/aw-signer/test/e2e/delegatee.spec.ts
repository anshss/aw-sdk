import { config } from '@dotenvx/dotenvx';
import { LIT_RPC } from '@lit-protocol/constants';
import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';

import { Admin } from '../../src/lib/admin';
import { Delegatee } from '../../src/lib/delegatee';
import { PkpInfo } from '../../src/lib/types';

// Load environment variables
config();

const ADMIN_PRIVATE_KEY = process.env.ADMIN_PRIVATE_KEY;
if (!ADMIN_PRIVATE_KEY) {
  throw new Error('ADMIN_PRIVATE_KEY environment variable is required');
}
const ADMIN_WALLET = new ethers.Wallet(
  ADMIN_PRIVATE_KEY,
  new ethers.providers.JsonRpcProvider(LIT_RPC.CHRONICLE_YELLOWSTONE)
);

const DELEGATEE_WALLET = ethers.Wallet.createRandom();
const DELEGATEE_ADDRESS = DELEGATEE_WALLET.address;

/**
 * @dev NOTE: Each test case is intended to run sequentially.
 * State does not reset between test cases, and each test cases expects
 * a certain state based on the previous test cases.
 */

describe('Delegatee E2E', () => {
  const ADMIN_STORAGE_PATH = path.join(
    __dirname,
    '../../.aw-signer-admin-storage'
  );
  const DELEGATEE_STORAGE_PATH = path.join(
    __dirname,
    '../../.aw-signer-delegatee-storage'
  );
  const ERC20_TRANSFER_TOOL_IPFS_CID =
    'QmdaabYYC3oDsNho3cJEYPuK62xpCmMrbhN9FmVnjBYpk2';
  const POLICY_IPFS_CID = 'QmTestPolicyIpfsCid';

  let admin: Admin;
  let delegatee: Delegatee;

  beforeAll(async () => {
    // Create Admin instance with real network connections
    admin = await Admin.create(
      { type: 'eoa', privateKey: ADMIN_PRIVATE_KEY },
      { litNetwork: 'datil-test' }
    );

    // Send 0.00000001 ETH to delegatee from admin
    const tx = await ADMIN_WALLET.sendTransaction({
      to: DELEGATEE_ADDRESS,
      value: ethers.utils.parseUnits('0.001', 'ether'),
    });
    await tx.wait();

    // Create Admin instance with real network connections
    delegatee = await Delegatee.create(DELEGATEE_WALLET.privateKey, {
      litNetwork: 'datil-test',
    });
  }, 30000); // Increase timeout for network connections

  afterAll(async () => {
    admin.disconnect();
    delegatee.disconnect();

    // Remove storage directory if it exists
    if (fs.existsSync(ADMIN_STORAGE_PATH)) {
      fs.rmSync(ADMIN_STORAGE_PATH, { recursive: true, force: true });
    }
    if (fs.existsSync(DELEGATEE_STORAGE_PATH)) {
      fs.rmSync(DELEGATEE_STORAGE_PATH, { recursive: true, force: true });
    }
  });

  describe.only('All Delegatee Tests', () => {
    let pkpMetadata: PkpInfo;

    beforeAll(async () => {
      // Mint a PKP to use for delegatee tests
      pkpMetadata = await admin.mintPkp();

      // Add the delegatee to the PKP
      await admin.addDelegatee(pkpMetadata.info.tokenId, DELEGATEE_ADDRESS);
    }, 60000);

    it('should retrieve delegated PKP for the delegatee', async () => {
      const delegatedPkps = await delegatee.getDelegatedPkps();
      expect(Array.isArray(delegatedPkps)).toBe(true);
      expect(delegatedPkps.length).toBe(1);

      expect(delegatedPkps[0].tokenId).toBe(pkpMetadata.info.tokenId);
      expect(delegatedPkps[0].ethAddress).toBe(pkpMetadata.info.ethAddress);
      expect(delegatedPkps[0].publicKey).toBe(
        `0x${pkpMetadata.info.publicKey}`
      );
    }, 60000);

    it('should retrieve no registered tools for the PKP', async () => {
      const registeredTools = await delegatee.getPermittedToolsForPkp(
        pkpMetadata.info.tokenId
      );
      expect(registeredTools).toHaveProperty('toolsWithPolicies');
      expect(registeredTools).toHaveProperty('toolsWithoutPolicies');
      expect(registeredTools).toHaveProperty('toolsUnknownWithPolicies');
      expect(registeredTools).toHaveProperty('toolsUnknownWithoutPolicies');

      expect(Object.keys(registeredTools.toolsWithPolicies).length).toBe(0);
      expect(Object.keys(registeredTools.toolsWithoutPolicies).length).toBe(0);
      expect(Object.keys(registeredTools.toolsUnknownWithPolicies).length).toBe(
        0
      );
      expect(registeredTools.toolsUnknownWithoutPolicies.length).toBe(0);
    }, 60000);

    it('should register a tool, permit it for the delegatee, and set a policy for it', async () => {
      const { litContractsTxReceipt, toolRegistryContractTxReceipt } =
        await admin.registerTool(
          pkpMetadata.info.tokenId,
          ERC20_TRANSFER_TOOL_IPFS_CID
        );

      expect(litContractsTxReceipt).toBeDefined();
      expect(litContractsTxReceipt.status).toBe(1);

      expect(toolRegistryContractTxReceipt).toBeDefined();
      expect(toolRegistryContractTxReceipt.status).toBe(1);

      let receipt = await admin.permitToolForDelegatee(
        pkpMetadata.info.tokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_ADDRESS
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      receipt = await admin.setToolPolicyForDelegatee(
        pkpMetadata.info.tokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_ADDRESS,
        POLICY_IPFS_CID,
        true
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);
    }, 60000);

    it('should retrieve registered tools with policy for the PKP', async () => {
      const registeredTools = await delegatee.getPermittedToolsForPkp(
        pkpMetadata.info.tokenId
      );
      expect(registeredTools).toHaveProperty('toolsWithPolicies');
      expect(registeredTools).toHaveProperty('toolsWithoutPolicies');
      expect(registeredTools).toHaveProperty('toolsUnknownWithPolicies');
      expect(registeredTools).toHaveProperty('toolsUnknownWithoutPolicies');

      const toolWithPolicy =
        registeredTools.toolsWithPolicies[ERC20_TRANSFER_TOOL_IPFS_CID];
      expect(toolWithPolicy).toBeDefined();
      expect(toolWithPolicy.ipfsCid).toBe(ERC20_TRANSFER_TOOL_IPFS_CID);
      expect(toolWithPolicy.toolEnabled).toBe(true);
      expect(toolWithPolicy.delegatee).toBe(DELEGATEE_ADDRESS);
      expect(toolWithPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolWithPolicy.policyEnabled).toBe(true);
    }, 60000);

    it('should retrieve the policy for a specific tool', async () => {
      const toolPolicy = await delegatee.getToolPolicy(
        pkpMetadata.info.tokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.delegatee).toBe(DELEGATEE_ADDRESS);
      expect(toolPolicy.enabled).toBe(true);
    }, 60000);

    it('should not retrieve the non-existent policy for a specific tool', async () => {
      await expect(
        delegatee.getToolPolicy(pkpMetadata.info.tokenId, 'non-existent-tool')
      ).rejects.toThrow(
        new RegExp(
          `call revert exception.*` +
            `method="getToolPoliciesForDelegatees\\(uint256,string\\[\\],address\\[\\]\\)".*` +
            `errorArgs=\\["non-existent-tool"\\].*` +
            `errorName="ToolNotFound".*` +
            `errorSignature="ToolNotFound\\(string\\)".*` +
            `code=CALL_EXCEPTION.*`
        )
      );
    }, 60000);

    it('should retrieve the tool via intent using a mock intent matcher', async () => {
      const mockIntentMatcher = {
        analyzeIntentAndMatchTool: jest.fn().mockResolvedValue({
          analysis: {},
          matchedTool: {
            name: 'Mock Tool',
            description: 'A mock tool for testing',
            ipfsCid: ERC20_TRANSFER_TOOL_IPFS_CID,
            parameters: {
              type: {},
              schema: {},
              descriptions: {},
              validate: () => true,
            },
            policy: {
              type: { type: 'mockPolicy' },
              version: '1.0',
              schema: {},
              encode: () => 'encodedPolicy',
              decode: () => ({ type: 'mockPolicy' }),
            },
            network: 'mockNetwork',
            toolEnabled: true,
            delegatee: DELEGATEE_ADDRESS,
            policyIpfsCid: POLICY_IPFS_CID,
            policyEnabled: true,
          },
          params: {
            foundParams: {},
            missingParams: [],
            validationErrors: [],
          },
        }),
      };

      const intent = 'mockIntent';
      const pkpTokenId = pkpMetadata.info.tokenId;

      const result = await delegatee.getToolViaIntent(
        pkpTokenId,
        intent,
        mockIntentMatcher
      );

      expect(mockIntentMatcher.analyzeIntentAndMatchTool).toHaveBeenCalledWith(
        intent,
        expect.arrayContaining([
          expect.objectContaining({
            name: 'ERC20Transfer',
            description: 'A Lit Action that sends ERC-20 tokens.',
            ipfsCid: ERC20_TRANSFER_TOOL_IPFS_CID,
            parameters: expect.objectContaining({
              descriptions: expect.objectContaining({
                pkpEthAddress: expect.any(String),
                tokenIn: expect.any(String),
                recipientAddress: expect.any(String),
                amountIn: expect.any(String),
                chainId: expect.any(String),
                rpcUrl: expect.any(String),
              }),
              validate: expect.any(Function),
            }),
            policy: expect.objectContaining({
              version: '1.0.0',
              encode: expect.any(Function),
              decode: expect.any(Function),
            }),
            network: 'datil-test',
            toolEnabled: true,
            delegatee: DELEGATEE_ADDRESS,
            policyIpfsCid: POLICY_IPFS_CID,
            policyEnabled: true,
          }),
        ])
      );
      expect(result).toBeDefined();
      expect(result.matchedTool).not.toBeNull();
      expect(result.matchedTool!.ipfsCid).toBe(ERC20_TRANSFER_TOOL_IPFS_CID);
    }, 60000);
  });
});
