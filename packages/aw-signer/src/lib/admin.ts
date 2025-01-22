import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import {
  AUTH_METHOD_SCOPE,
  AUTH_METHOD_SCOPE_VALUES,
} from '@lit-protocol/constants';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { ethers } from 'ethers';

import { AdminConfig, AgentConfig, LitNetwork } from './types';
import {
  DEFAULT_REGISTRY_CONFIG,
  getPkpToolRegistryContract,
  getRegisteredToolsAndDelegatees,
  getToolPolicy,
} from './utils/pkp-tool-registry';
import { LocalStorage } from './utils/storage';
import { loadPkpsFromStorage, mintPkp, savePkpsToStorage } from './utils/pkp';
import { AwSignerError, AwSignerErrorType } from './errors';

/**
 * The `Admin` class is responsible for managing the Admin role in the Lit Protocol.
 * It handles tasks such as transferring ownership, permitting tools, managing policies, and managing delegatees.
 */
export class Admin {
  private static readonly DEFAULT_STORAGE_PATH = './.aw-signer-admin-storage';
  // TODO: Add min balance check
  // private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly storage: LocalStorage;
  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly litContracts: LitContracts;
  private readonly toolRegistryContract: ethers.Contract;
  private readonly adminWallet: ethers.Wallet;

  public readonly litNetwork: LitNetwork;
  /**
   * Private constructor for the Admin class.
   * @param litNetwork - The Lit network to use.
   * @param litNodeClient - An instance of `LitNodeClientNodeJs`.
   * @param litContracts - An instance of `LitContracts`.
   * @param toolRegistryContract - An instance of the tool policy registry contract.
   * @param adminWallet - The wallet used for Admin operations.
   * @param pkpInfo - Information about the PKP (Programmable Key Pair).
   */
  private constructor(
    storage: LocalStorage,
    litNetwork: LitNetwork,
    litNodeClient: LitNodeClientNodeJs,
    litContracts: LitContracts,
    toolRegistryContract: ethers.Contract,
    adminWallet: ethers.Wallet
  ) {
    this.storage = storage;
    this.litNetwork = litNetwork;
    this.litNodeClient = litNodeClient;
    this.litContracts = litContracts;
    this.toolRegistryContract = toolRegistryContract;
    this.adminWallet = adminWallet;
  }

  private static async removePkpFromStorage(
    storage: LocalStorage,
    pkpTokenId: string
  ) {
    const pkps = loadPkpsFromStorage(storage);
    const index = pkps.findIndex((p) => p.info.tokenId === pkpTokenId);

    if (index === -1) {
      throw new AwSignerError(
        AwSignerErrorType.ADMIN_PKP_NOT_FOUND,
        `PKP with tokenId ${pkpTokenId} not found in storage`
      );
    }

    pkps.splice(index, 1);
    savePkpsToStorage(storage, pkps);
  }

  /**
   * Creates an instance of the `Admin` class.
   * Initializes the Lit node client, contracts, and PKP.
   *
   * @param adminConfig - Configuration for the Admin role.
   * @param agentConfig - Configuration for the agent, including the Lit network and debug mode.
   * @returns A promise that resolves to an instance of the `Admin` class.
   * @throws {AwSignerError} If the Lit network is not provided or the private key is missing.
   */
  public static async create(
    adminConfig: AdminConfig,
    { litNetwork, debug = false }: AgentConfig = {}
  ) {
    if (!litNetwork) {
      throw new AwSignerError(
        AwSignerErrorType.ADMIN_MISSING_LIT_NETWORK,
        'Lit network not provided'
      );
    }

    const storage = new LocalStorage(Admin.DEFAULT_STORAGE_PATH);

    const toolRegistryConfig = DEFAULT_REGISTRY_CONFIG[litNetwork];

    const provider = new ethers.providers.JsonRpcProvider(
      toolRegistryConfig.rpcUrl
    );

    let adminWallet: ethers.Wallet;
    if (adminConfig.type === 'eoa') {
      const storedPrivateKey = storage.getItem('privateKey');
      const adminPrivateKey = adminConfig.privateKey || storedPrivateKey;

      if (adminPrivateKey === null) {
        throw new AwSignerError(
          AwSignerErrorType.ADMIN_MISSING_PRIVATE_KEY,
          'Admin private key not provided and not found in storage. Please provide a private key.'
        );
      }

      // Only save if not already stored
      if (!storedPrivateKey) {
        storage.setItem('privateKey', adminPrivateKey);
      }

      adminWallet = new ethers.Wallet(adminPrivateKey, provider);
    } else {
      throw new AwSignerError(
        AwSignerErrorType.ADMIN_MULTISIG_NOT_IMPLEMENTED,
        'Multisig admin not implemented, use EOA instead.'
      );
    }

    const litNodeClient = new LitNodeClientNodeJs({
      litNetwork,
      debug,
    });
    await litNodeClient.connect();

    const litContracts = new LitContracts({
      signer: adminWallet,
      network: litNetwork,
      debug,
    });
    await litContracts.connect();

    return new Admin(
      storage,
      litNetwork,
      litNodeClient,
      litContracts,
      getPkpToolRegistryContract(toolRegistryConfig, adminWallet),
      adminWallet
    );
  }

  public async getPkps() {
    return loadPkpsFromStorage(this.storage);
  }

  public async getPkpByTokenId(tokenId: string) {
    const pkps = await this.getPkps();
    const pkp = pkps.find((p) => p.info.tokenId === tokenId);
    if (!pkp) {
      throw new AwSignerError(
        AwSignerErrorType.ADMIN_PKP_NOT_FOUND,
        `PKP with tokenId ${tokenId} not found in storage`
      );
    }

    return pkp;
  }

  public async mintPkp() {
    const pkps = await this.getPkps();
    const mintMetadata = await mintPkp(this.litContracts, this.adminWallet);
    pkps.push(mintMetadata);
    savePkpsToStorage(this.storage, pkps);

    return mintMetadata;
  }

  /**
   * Transfers ownership of the PKP to a new owner.
   * @param newOwner - The address of the new owner.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the Admin instance is not properly initialized.
   */
  public async transferPkpOwnership(pkpTokenId: string, newOwner: string) {
    if (!this.litContracts) {
      throw new Error('Not properly initialized');
    }

    const pkp = await this.getPkpByTokenId(pkpTokenId);
    const tx = await this.litContracts.pkpNftContract.write[
      'safeTransferFrom(address,address,uint256)'
    ](this.adminWallet.address, newOwner, pkp.info.tokenId);

    const receipt = await tx.wait();
    if (receipt.status === 0) {
      throw new AwSignerError(
        AwSignerErrorType.ADMIN_PKP_TRANSFER_FAILED,
        'PKP transfer failed'
      );
    }

    await Admin.removePkpFromStorage(this.storage, pkpTokenId);

    return receipt;
  }

  /**
   * Permits a tool to be used with the PKP.
   * @param ipfsCid - The IPFS CID of the tool.
   * @param signingScopes - The signing scopes for the tool (default is `SignAnything`).
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the Admin instance is not properly initialized.
   */
  public async registerTool(
    pkpTokenId: string,
    ipfsCid: string,
    options: {
      signingScopes?: AUTH_METHOD_SCOPE_VALUES[];
      enableTools?: boolean;
    } = {}
  ) {
    const {
      signingScopes = [AUTH_METHOD_SCOPE.SignAnything],
      enableTools = true,
    } = options;

    if (!this.litContracts) {
      throw new Error('Not properly initialized');
    }

    const litContractsTxReceipt = await this.litContracts.addPermittedAction({
      ipfsId: ipfsCid,
      authMethodScopes: signingScopes,
      pkpTokenId: (await this.getPkpByTokenId(pkpTokenId)).info.tokenId,
    });

    const toolRegistryContractTx =
      await this.toolRegistryContract.registerTools(
        pkpTokenId,
        [ipfsCid],
        enableTools
      );

    return {
      litContractsTxReceipt,
      toolRegistryContractTxReceipt: await toolRegistryContractTx.wait(),
    };
  }

  // /**
  //  * Removes a tool from the list of permitted tools.
  //  * @param ipfsCid - The IPFS CID of the tool.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the Admin instance is not properly initialized.
  //  */
  // public async removeTool(pkpTokenId: string, ipfsCid: string) {
  //   if (!this.litContracts) {
  //     throw new Error('Not properly initialized');
  //   }

  //   return this.litContracts.pkpPermissionsContractUtils.write.revokePermittedAction(
  //     (await this.getPkpByTokenId(pkpTokenId)).info.tokenId,
  //     ipfsCid
  //   );
  // }

  /**
   * Enables a tool for a given PKP.
   * @param pkpTokenId - The token ID of the PKP.
   * @param toolIpfsCid - The IPFS CID of the tool to be enabled.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async enableTool(pkpTokenId: string, toolIpfsCid: string) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolRegistryContract.enableTools(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      [toolIpfsCid]
    );

    return await tx.wait();
  }

  // /**
  //  * Disables a tool for a given PKP.
  //  * @param pkpTokenId - The token ID of the PKP.
  //  * @param toolIpfsCid - The IPFS CID of the tool to be disabled.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async disableTool(pkpTokenId: string, toolIpfsCid: string) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.disableTools(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     [toolIpfsCid]
  //   );

  //   return await tx.wait();
  // }

  /**
   * Get a registered tool by its IPFS CID for a given PKP.
   * @param pkpTokenId - The token ID of the PKP.
   * @param toolIpfsCid - The IPFS CID of the tool to be retrieved.
   * @returns A promise that resolves to the tool information.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async getRegisteredTool(pkpTokenId: string, toolIpfsCid: string) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const toolInfos = await this.toolRegistryContract.getRegisteredTools(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      [toolIpfsCid]
    );

    return toolInfos[0];
  }

  /**
   * Get all registered tools and categorize them based on whether they have policies
   * @returns Object containing:
   * - toolsWithPolicies: Object mapping tool IPFS CIDs to their metadata and delegatee policies
   * - toolsWithoutPolicies: Array of tools that don't have policies
   * - toolsUnknownWithPolicies: Object mapping unknown tool IPFS CIDs to their delegatee policies
   * - toolsUnknownWithoutPolicies: Array of tool CIDs without policies that aren't in the registry
   */
  public async getRegisteredToolsAndDelegateesForPkp(pkpTokenId: string) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const registeredTools = await getRegisteredToolsAndDelegatees(
      this.toolRegistryContract,
      this.litContracts,
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId
    );

    return registeredTools;
  }

  /**
   * Retrieves all delegatees for the PKP.
   * @returns An array of delegatee addresses.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async getDelegatees(pkpTokenId: string): Promise<string[]> {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolRegistryContract.getDelegatees(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId
    );
  }

  /**
   * Checks if an address is a delegatee for the PKP.
   * @param delegatee - The address to check.
   * @returns A promise that resolves to a boolean indicating whether the address is a delegatee.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async isDelegatee(pkpTokenId: string, delegatee: string) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolRegistryContract.isPkpDelegatee(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      ethers.utils.getAddress(delegatee)
    );
  }

  /**
   * Adds a delegatee for the PKP.
   * @param delegatee - The address to add as a delegatee.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async addDelegatee(pkpTokenId: string, delegatee: string) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolRegistryContract.addDelegatees(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      [delegatee]
    );

    return await tx.wait();
  }

  /**
   * Permits a tool for a specific delegatee.
   * @param pkpTokenId - The PKP token ID.
   * @param toolIpfsCid - The IPFS CID of the tool.
   * @param delegatee - The address of the delegatee.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async permitToolForDelegatee(
    pkpTokenId: string,
    toolIpfsCid: string,
    delegatee: string
  ) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolRegistryContract.permitToolsForDelegatees(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      [toolIpfsCid],
      [delegatee]
    );

    return await tx.wait();
  }

  // /**
  //  * Unpermits a tool for a specific delegatee.
  //  * @param pkpTokenId - The PKP token ID.
  //  * @param toolIpfsCid - The IPFS CID of the tool.
  //  * @param delegatee - The address of the delegatee.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async unpermitToolForDelegatee(
  //   pkpTokenId: string,
  //   toolIpfsCid: string,
  //   delegatee: string
  // ) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.unpermitToolsForDelegatees(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     [toolIpfsCid],
  //     [delegatee]
  //   );

  //   return await tx.wait();
  // }

  /**
   * Retrieves the policy for a specific tool.
   * @param ipfsCid - The IPFS CID of the tool.
   * @returns An object containing the policy and version for the tool.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async getToolPolicyForDelegatee(
    pkpTokenId: string,
    ipfsCid: string,
    delegatee: string
  ): Promise<{ policyIpfsCid: string; enabled: boolean }> {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return getToolPolicy(
      this.toolRegistryContract,
      (await this.getPkpByTokenId(pkpTokenId)).info.tokenId,
      ipfsCid,
      delegatee
    );
  }

  /**
   * Sets or updates a policy for a specific tool.
   * @param ipfsCid - The IPFS CID of the tool.
   * @param policy - The policy bytes (must be ABI encoded).
   * @param version - The version of the policy.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async setToolPolicyForDelegatee(
    pkpTokenId: string,
    ipfsCid: string,
    delegatee: string,
    policyIpfsCid: string,
    enablePolicies: boolean
  ) {
    if (!this.toolRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolRegistryContract.setToolPoliciesForDelegatees(
      (
        await this.getPkpByTokenId(pkpTokenId)
      ).info.tokenId,
      [ipfsCid],
      [delegatee],
      [policyIpfsCid],
      enablePolicies
    );

    return await tx.wait();
  }

  // /**
  //  * Removes the policy for a specific tool.
  //  * @param ipfsCid - The IPFS CID of the tool.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async removeToolPolicy(pkpTokenId: string, ipfsCid: string) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.removeToolPolicy(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     ipfsCid
  //   );

  //   return await tx.wait();
  // }

  // /**
  //  * Removes a delegatee for the PKP.
  //  * @param delegatee - The address to remove as a delegatee.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async removeDelegatee(pkpTokenId: string, delegatee: string) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.removeDelegatee(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     delegatee
  //   );

  //   return await tx.wait();
  // }

  // /**
  //  * Adds multiple delegatees for the PKP in a single transaction.
  //  * @param delegatees - An array of addresses to add as delegatees.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async batchAddDelegatees(pkpTokenId: string, delegatees: string[]) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.batchAddDelegatees(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     delegatees
  //   );

  //   return await tx.wait();
  // }

  // /**
  //  * Removes multiple delegatees for the PKP in a single transaction.
  //  * @param delegatees - An array of addresses to remove as delegatees.
  //  * @returns A promise that resolves to the transaction receipt.
  //  * @throws If the tool policy registry contract is not initialized.
  //  */
  // public async batchRemoveDelegatees(pkpTokenId: string, delegatees: string[]) {
  //   if (!this.toolRegistryContract) {
  //     throw new Error('Tool policy manager not initialized');
  //   }

  //   const tx = await this.toolRegistryContract.batchRemoveDelegatees(
  //     (
  //       await this.getPkpByTokenId(pkpTokenId)
  //     ).info.tokenId,
  //     delegatees
  //   );

  //   return await tx.wait();
  // }

  /**
   * Disconnects the Lit node client.
   */
  public disconnect() {
    this.litNodeClient.disconnect();
  }
}
