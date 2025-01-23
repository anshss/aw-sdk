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

/**
 * @dev NOTE: Each test case is intended to run sequentially.
 * State does not reset between test cases, and each test cases expects
 * a certain state based on the previous test cases.
 */

describe('Admin E2E', () => {
  const STORAGE_PATH = path.join(__dirname, '../../.aw-signer-admin-storage');
  const ERC20_TRANSFER_TOOL_IPFS_CID =
    'QmdaabYYC3oDsNho3cJEYPuK62xpCmMrbhN9FmVnjBYpk2';
  const DELEGATEE_1 = ethers.Wallet.createRandom().address;
  //   const DELEGATEE_2 = ethers.Wallet.createRandom().address;
  const POLICY_IPFS_CID = 'QmTestPolicyIpfsCid';
  const POLICY_1_ENABLED = true;
  const TEST_PARAM_NAME = 'testParamName';
  const TEST_PARAM_NAME_2 = 'testParamName2';
  const TEST_PARAM_VALUE_BYTES = ethers.utils.toUtf8Bytes('testParamValue');
  const TEST_PARAM_VALUE_2_BYTES = ethers.utils.toUtf8Bytes('testParamValue2');
  const TEST_PARAM_VALUE_HEX = ethers.utils.hexlify(TEST_PARAM_VALUE_BYTES);
  const TEST_PARAM_VALUE_2_HEX = ethers.utils.hexlify(TEST_PARAM_VALUE_2_BYTES);

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

  describe('PKP Management', () => {
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

    it('should check that a tool is not registered for PKP', async () => {
      const { isRegistered, isEnabled } = await admin.isToolRegistered(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(isRegistered).toBe(false);
      expect(isEnabled).toBe(false);
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

      // Retrieve the registered tool
      const toolInfo = await admin.getRegisteredTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(toolInfo).toBeDefined();
      expect(toolInfo.toolIpfsCid).toBe(ERC20_TRANSFER_TOOL_IPFS_CID);
      expect(toolInfo.toolEnabled).toBe(true);
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
      expect(Array.isArray(erc20Tool.delegatees)).toBe(true);
      expect(erc20Tool.delegatees).toHaveLength(0);
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

      const delegatees = await admin.getDelegatees(pkpTokenId);

      expect(delegatees).toBeDefined();
      expect(Array.isArray(delegatees)).toBe(true);
      expect(delegatees.length).toBe(1);
      expect(delegatees[0]).toBe(DELEGATEE_1);
    }, 60000);

    it('should retrieve the empty policy for a specific tool and delegatee', async () => {
      // Retrieve the tool policy for the delegatee
      const toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe('');
      expect(toolPolicy.enabled).toBe(false);
    }, 60000);

    it('should set the policy for a specific tool and delegatee', async () => {
      const txReceipt = await admin.setToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        POLICY_IPFS_CID,
        POLICY_1_ENABLED
      );

      expect(txReceipt).toBeDefined();
      expect(txReceipt.status).toBe(1);

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
      expect(Array.isArray(erc20Tool.delegatees)).toBe(true);
      expect(erc20Tool.delegatees).toContain(DELEGATEE_1);
      expect(typeof erc20Tool.delegateePolicies).toBe('object');

      // Check the delegatee policy structure
      const delegateePolicy = erc20Tool.delegateePolicies[DELEGATEE_1];
      expect(delegateePolicy).toBeDefined();
      expect(delegateePolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(delegateePolicy.policyEnabled).toBe(POLICY_1_ENABLED);
    }, 60000);

    it('should check that a tool is registered for PKP', async () => {
      const { isRegistered, isEnabled } = await admin.isToolRegistered(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(isRegistered).toBe(true);
      expect(isEnabled).toBe(true);
    }, 60000);

    it('should check that a tool is not permitted for a specific delegatee', async () => {
      const { isPermitted, isEnabled } =
        await admin.isToolPermittedForDelegatee(
          pkpTokenId,
          ERC20_TRANSFER_TOOL_IPFS_CID,
          DELEGATEE_1
        );

      expect(isPermitted).toBe(false);
      expect(isEnabled).toBe(true);
    }, 60000);

    it('should permit a tool for a specific delegatee', async () => {
      const receipt = await admin.permitToolForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      const { isPermitted, isEnabled } =
        await admin.isToolPermittedForDelegatee(
          pkpTokenId,
          ERC20_TRANSFER_TOOL_IPFS_CID,
          DELEGATEE_1
        );

      expect(isPermitted).toBe(true);
      expect(isEnabled).toBe(true);
    }, 60000);

    it('should disable a tool for a given PKP', async () => {
      // Verify the tool is enabled
      let { isRegistered, isEnabled } = await admin.isToolRegistered(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(isRegistered).toBe(true);
      expect(isEnabled).toBe(true);

      // Now, disable the tool for the PKP
      const receipt = await admin.disableTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the tool is disabled
      ({ isRegistered, isEnabled } = await admin.isToolRegistered(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      ));

      expect(isRegistered).toBe(true);
      expect(isEnabled).toBe(false);
    }, 60000);

    it('should disable a policy for a specific tool and delegatee', async () => {
      // Verify the policy is enabled
      let toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(true);

      // Now, disable the policy for the tool and delegatee
      const receipt = await admin.disableToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the policy is disabled
      toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(false);
    }, 60000);

    it('should enable a policy for a specific tool and delegatee', async () => {
      // Verify the policy is disabled
      let toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(false);

      // Now, enable the policy for the tool and delegatee
      const receipt = await admin.enableToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the policy is enabled
      toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(true);
    }, 60000);

    it('should set policy parameters for a specific tool and delegatee', async () => {
      // Define the parameters to set
      const parameterNames = [TEST_PARAM_NAME, TEST_PARAM_NAME_2];
      const parameterValues = [
        TEST_PARAM_VALUE_BYTES,
        TEST_PARAM_VALUE_2_BYTES,
      ];

      // Set the policy parameters for the tool and delegatee
      const receipt = await admin.setToolPolicyParametersForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        parameterNames,
        parameterValues
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the policy parameters are set
      const parameters = await admin.getToolPolicyParametersForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        parameterNames
      );

      expect(parameters).toBeDefined();
      expect(parameters.length).toBe(2);
      expect(parameters[0].name).toBe(TEST_PARAM_NAME);
      expect(parameters[0].value).toBe(TEST_PARAM_VALUE_HEX);
      expect(parameters[1].name).toBe(TEST_PARAM_NAME_2);
      expect(parameters[1].value).toBe(TEST_PARAM_VALUE_2_HEX);

      // Get the specific policy parameter for the tool and delegatee
      const parameter = await admin.getToolPolicyParameterForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        TEST_PARAM_NAME
      );

      expect(parameter).toBeDefined();
      expect(parameter.length).toBe(1);
      expect(parameter[0].name).toBe(TEST_PARAM_NAME);
      expect(parameter[0].value).toBe(TEST_PARAM_VALUE_HEX);
    }, 60000);

    it('should remove policy parameters for a specific tool and delegatee', async () => {
      // Define the parameters to set and then remove
      const parameterNames = [TEST_PARAM_NAME, TEST_PARAM_NAME_2];

      // Verify the policy parameters are set
      let parameters = await admin.getToolPolicyParametersForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        parameterNames
      );

      expect(parameters).toBeDefined();
      expect(parameters.length).toBe(2);
      expect(parameters[0].name).toBe(TEST_PARAM_NAME);
      expect(parameters[0].value).toBe(TEST_PARAM_VALUE_HEX);
      expect(parameters[1].name).toBe(TEST_PARAM_NAME_2);
      expect(parameters[1].value).toBe(TEST_PARAM_VALUE_2_HEX);

      // Now, remove the policy parameters for the tool and delegatee
      const receipt = await admin.removeToolPolicyParametersForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        [TEST_PARAM_NAME]
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the policy parameter is removed
      parameters = await admin.getToolPolicyParametersForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1,
        [TEST_PARAM_NAME, TEST_PARAM_NAME_2]
      );

      expect(parameters).toBeDefined();
      expect(parameters.length).toBe(2);
      expect(parameters[0].name).toBe(TEST_PARAM_NAME);
      expect(parameters[0].value).toBe('0x');
      expect(parameters[1].name).toBe(TEST_PARAM_NAME_2);
      expect(parameters[1].value).toBe(TEST_PARAM_VALUE_2_HEX);
    }, 60000);

    it('should remove the policy for a specific tool and delegatee', async () => {
      // Verify the policy is set
      let toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe(POLICY_IPFS_CID);
      expect(toolPolicy.enabled).toBe(POLICY_1_ENABLED);

      // Now, remove the policy for the tool and delegatee
      const receipt = await admin.removeToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the policy is removed
      toolPolicy = await admin.getToolPolicyForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(toolPolicy).toBeDefined();
      expect(toolPolicy.policyIpfsCid).toBe('');
      expect(toolPolicy.enabled).toBe(false);
    }, 60000);

    it('should unpermit a tool for a specific delegatee', async () => {
      // First, permit the tool for the delegatee
      let receipt = await admin.permitToolForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the tool is permitted
      let { isPermitted, isEnabled } = await admin.isToolPermittedForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(isPermitted).toBe(true);
      expect(isEnabled).toBe(false);

      // Now, unpermit the tool for the delegatee
      receipt = await admin.unpermitToolForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      );

      expect(receipt).toBeDefined();
      expect(receipt.status).toBe(1);

      // Verify the tool is no longer permitted
      ({ isPermitted, isEnabled } = await admin.isToolPermittedForDelegatee(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID,
        DELEGATEE_1
      ));

      expect(isPermitted).toBe(false);
      expect(isEnabled).toBe(false);
    }, 60000);

    it('should remove a tool', async () => {
      // Verify the tool is registered
      const tool = await admin.getRegisteredTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );
      expect(tool).toBeDefined();
      expect(tool[0]).toBe(ERC20_TRANSFER_TOOL_IPFS_CID);
      expect(tool[1]).toBe(false);

      // Now, remove the tool
      const receipt = await admin.removeTool(
        pkpTokenId,
        ERC20_TRANSFER_TOOL_IPFS_CID
      );

      expect(receipt).toBeDefined();
      expect(receipt.revokePermittedActionTxReceipt.status).toBe(1);
      expect(receipt.removeToolsTxReceipt.status).toBe(1);

      // Verify the tool is no longer registered
      await expect(
        admin.getRegisteredTool(pkpTokenId, ERC20_TRANSFER_TOOL_IPFS_CID)
      ).rejects.toThrow(
        new RegExp(
          `call revert exception.*` +
            `method="getRegisteredTools\\(uint256,string\\[\\]\\)".*` +
            `errorArgs=\\["${ERC20_TRANSFER_TOOL_IPFS_CID}"\\].*` +
            `errorName="ToolNotFound".*` +
            `errorSignature="ToolNotFound\\(string\\)".*` +
            `code=CALL_EXCEPTION`
        )
      );
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
