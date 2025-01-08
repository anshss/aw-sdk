import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import {
  AUTH_METHOD_SCOPE,
  AUTH_METHOD_SCOPE_VALUES,
} from '@lit-protocol/constants';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { ethers } from 'ethers';

import {
  AdminConfig,
  AgentConfig,
  LitNetwork,
  PkpInfo,
  UnknownRegisteredToolWithPolicy,
} from './types';
import {
  DEFAULT_REGISTRY_CONFIG,
  getPkpToolPolicyRegistryContract,
  getRegisteredTools,
  getToolPolicy,
} from './utils/pkp-tool-registry';
import { LocalStorage } from './utils/storage';
import { loadPkpFromStorage, mintPkp, savePkpToStorage } from './utils/pkp';
import { FssSignerError, FssSignerErrorType } from './errors';
import { FssTool } from '@lit-protocol/fss-tool';

/**
 * The `Admin` class is responsible for managing the Admin role in the Lit Protocol.
 * It handles tasks such as transferring ownership, permitting tools, managing policies, and managing delegatees.
 */
export class Admin {
  private static readonly DEFAULT_STORAGE_PATH = './.fss-signer-admin-storage';
  // TODO: Add min balance check
  // private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly litContracts: LitContracts;
  private readonly toolPolicyRegistryContract: ethers.Contract;
  private readonly adminWallet: ethers.Wallet;
  private readonly pkpInfo: PkpInfo;

  public readonly litNetwork: LitNetwork;

  /**
   * Private constructor for the Admin class.
   * @param litNetwork - The Lit network to use.
   * @param litNodeClient - An instance of `LitNodeClientNodeJs`.
   * @param litContracts - An instance of `LitContracts`.
   * @param toolPolicyRegistryContract - An instance of the tool policy registry contract.
   * @param adminWallet - The wallet used for Admin operations.
   * @param pkpInfo - Information about the PKP (Programmable Key Pair).
   */
  private constructor(
    litNetwork: LitNetwork,
    litNodeClient: LitNodeClientNodeJs,
    litContracts: LitContracts,
    toolPolicyRegistryContract: ethers.Contract,
    adminWallet: ethers.Wallet,
    pkpInfo: PkpInfo
  ) {
    this.litNetwork = litNetwork;
    this.litNodeClient = litNodeClient;
    this.litContracts = litContracts;
    this.toolPolicyRegistryContract = toolPolicyRegistryContract;
    this.adminWallet = adminWallet;
    this.pkpInfo = pkpInfo;
  }

  /**
   * Retrieves or mints a PKP (Programmable Key Pair) for the Admin.
   * If a PKP is already stored, it is loaded; otherwise, a new PKP is minted.
   *
   * @param litContracts - An instance of `LitContracts`.
   * @param wallet - The wallet used for Admin operations.
   * @param storage - An instance of `LocalStorage` for storing PKP information.
   * @returns A promise that resolves to the PKP information.
   */
  private static async getPkp(
    litContracts: LitContracts,
    wallet: ethers.Wallet,
    storage: LocalStorage
  ) {
    const pkpInfo = loadPkpFromStorage(storage);
    if (pkpInfo !== null) {
      return pkpInfo;
    }

    const mintMetadata = await mintPkp(litContracts, wallet);
    savePkpToStorage(storage, mintMetadata);

    return mintMetadata;
  }

  /**
   * Creates an instance of the `Admin` class.
   * Initializes the Lit node client, contracts, and PKP.
   *
   * @param adminConfig - Configuration for the Admin role.
   * @param agentConfig - Configuration for the agent, including the Lit network and debug mode.
   * @returns A promise that resolves to an instance of the `Admin` class.
   * @throws {FssSignerError} If the Lit network is not provided or the private key is missing.
   */
  public static async create(
    adminConfig: AdminConfig,
    {
      litNetwork,
      debug = false,
      toolPolicyRegistryConfig = DEFAULT_REGISTRY_CONFIG,
    }: AgentConfig = {}
  ) {
    if (!litNetwork) {
      throw new FssSignerError(
        FssSignerErrorType.ADMIN_MISSING_LIT_NETWORK,
        'Lit network not provided'
      );
    }

    const storage = new LocalStorage(Admin.DEFAULT_STORAGE_PATH);

    const provider = new ethers.providers.JsonRpcProvider(
      toolPolicyRegistryConfig.rpcUrl
    );

    let adminWallet: ethers.Wallet;
    if (adminConfig.type === 'eoa') {
      const storedPrivateKey = storage.getItem('privateKey');
      const adminPrivateKey = adminConfig.privateKey || storedPrivateKey;

      if (adminPrivateKey === null) {
        throw new FssSignerError(
          FssSignerErrorType.ADMIN_MISSING_PRIVATE_KEY,
          'Admin private key not provided and not found in storage. Please provide a private key.'
        );
      }

      // Only save if not already stored
      if (!storedPrivateKey) {
        storage.setItem('privateKey', adminPrivateKey);
      }

      adminWallet = new ethers.Wallet(adminPrivateKey, provider);
    } else {
      throw new FssSignerError(
        FssSignerErrorType.ADMIN_MULTISIG_NOT_IMPLEMENTED,
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
      litNetwork,
      litNodeClient,
      litContracts,
      getPkpToolPolicyRegistryContract(toolPolicyRegistryConfig, adminWallet),
      adminWallet,
      await Admin.getPkp(litContracts, adminWallet, storage)
    );
  }

  /**
   * Transfers ownership of the PKP to a new owner.
   * @param newOwner - The address of the new owner.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the Admin instance is not properly initialized.
   */
  public async transferOwnership(newOwner: string) {
    if (!this.litContracts || !this.pkpInfo) {
      throw new Error('Not properly initialized');
    }

    return this.litContracts.pkpNftContract.write[
      'safeTransferFrom(address,address,uint256)'
    ](this.adminWallet.address, newOwner, this.pkpInfo.info.tokenId);
  }

  /**
   * Permits a tool to be used with the PKP.
   * @param ipfsCid - The IPFS CID of the tool.
   * @param signingScopes - The signing scopes for the tool (default is `SignAnything`).
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the Admin instance is not properly initialized.
   */
  public async permitTool({
    ipfsCid,
    signingScopes = [AUTH_METHOD_SCOPE.SignAnything],
  }: {
    ipfsCid: string;
    signingScopes?: AUTH_METHOD_SCOPE_VALUES[];
  }) {
    if (!this.litContracts || !this.pkpInfo) {
      throw new Error('Not properly initialized');
    }

    return this.litContracts.addPermittedAction({
      ipfsId: ipfsCid,
      authMethodScopes: signingScopes,
      pkpTokenId: this.pkpInfo.info.tokenId,
    });
  }

  /**
   * Removes a tool from the list of permitted tools.
   * @param ipfsCid - The IPFS CID of the tool.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the Admin instance is not properly initialized.
   */
  public async removeTool(ipfsCid: string) {
    if (!this.litContracts || !this.pkpInfo) {
      throw new Error('Not properly initialized');
    }

    return this.litContracts.pkpPermissionsContractUtils.write.revokePermittedAction(
      this.pkpInfo.info.tokenId,
      ipfsCid
    );
  }

  /**

   * Get all registered tools and categorize them based on whether they have policies
   * @returns Object containing:
   * - toolsWithPolicies: Array of tools that have policies and match the current network
   * - toolsWithoutPolicies: Array of tools that don't have policies and match the current network
   * - toolsUnknownWithPolicies: Array of tools with policies that aren't in the registry
   * - toolsUnknownWithoutPolicies: Array of tool CIDs without policies that aren't in the registry
   */
  public async getRegisteredToolsForPkp(): Promise<{
    toolsWithPolicies: Array<FssTool<any, any>>;
    toolsWithoutPolicies: Array<FssTool<any, any>>;
    toolsUnknownWithPolicies: UnknownRegisteredToolWithPolicy[];
    toolsUnknownWithoutPolicies: string[];
  }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const registeredTools = await getRegisteredTools(
      this.toolPolicyRegistryContract,
      this.litContracts,
      this.pkpInfo.info.tokenId
    );

    return {
      toolsWithPolicies: registeredTools.toolsWithPolicies
        .filter((tool) => tool.network === this.litNetwork)
        .map((t) => t.tool),
      toolsWithoutPolicies: registeredTools.toolsWithoutPolicies
        .filter((tool) => tool.network === this.litNetwork)
        .map((t) => t.tool),
      toolsUnknownWithPolicies: registeredTools.toolsUnknownWithPolicies,
      toolsUnknownWithoutPolicies: registeredTools.toolsUnknownWithoutPolicies,
    };
  }

  /**
   * Retrieves the policy for a specific tool.
   * @param ipfsCid - The IPFS CID of the tool.
   * @returns An object containing the policy and version for the tool.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async getToolPolicy(
    ipfsCid: string
  ): Promise<{ policy: string; version: string }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return getToolPolicy(
      this.toolPolicyRegistryContract,
      this.pkpInfo.info.tokenId,
      ipfsCid
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
  public async setToolPolicy(ipfsCid: string, policy: string, version: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.setToolPolicy(
      this.pkpInfo.info.tokenId,
      ipfsCid,
      policy,
      version
    );

    return await tx.wait();
  }

  /**
   * Removes the policy for a specific tool.
   * @param ipfsCid - The IPFS CID of the tool.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async removeToolPolicy(ipfsCid: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.removeToolPolicy(
      this.pkpInfo.info.tokenId,
      ipfsCid
    );

    return await tx.wait();
  }

  /**
   * Retrieves all delegatees for the PKP.
   * @returns An array of delegatee addresses.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async getDelegatees(): Promise<string[]> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolPolicyRegistryContract.getDelegatees(
      this.pkpInfo.info.tokenId
    );
  }

  /**
   * Checks if an address is a delegatee for the PKP.
   * @param delegatee - The address to check.
   * @returns A promise that resolves to a boolean indicating whether the address is a delegatee.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async isDelegatee(delegatee: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolPolicyRegistryContract.isDelegateeOf(
      this.pkpInfo.info.tokenId,
      ethers.utils.getAddress(delegatee)
    );
  }

  /**
   * Adds a delegatee for the PKP.
   * @param delegatee - The address to add as a delegatee.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async addDelegatee(delegatee: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.addDelegatee(
      this.pkpInfo.info.tokenId,
      delegatee
    );

    return await tx.wait();
  }

  /**
   * Removes a delegatee for the PKP.
   * @param delegatee - The address to remove as a delegatee.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async removeDelegatee(delegatee: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.removeDelegatee(
      this.pkpInfo.info.tokenId,
      delegatee
    );

    return await tx.wait();
  }

  /**
   * Adds multiple delegatees for the PKP in a single transaction.
   * @param delegatees - An array of addresses to add as delegatees.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async batchAddDelegatees(delegatees: string[]) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.batchAddDelegatees(
      this.pkpInfo.info.tokenId,
      delegatees
    );

    return await tx.wait();
  }

  /**
   * Removes multiple delegatees for the PKP in a single transaction.
   * @param delegatees - An array of addresses to remove as delegatees.
   * @returns A promise that resolves to the transaction receipt.
   * @throws If the tool policy registry contract is not initialized.
   */
  public async batchRemoveDelegatees(delegatees: string[]) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.batchRemoveDelegatees(
      this.pkpInfo.info.tokenId,
      delegatees
    );

    return await tx.wait();
  }

  /**
   * Disconnects the Lit node client.
   */
  public disconnect() {
    this.litNodeClient.disconnect();
  }
}
