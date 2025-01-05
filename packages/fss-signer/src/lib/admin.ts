import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import {
  AUTH_METHOD_SCOPE,
  AUTH_METHOD_SCOPE_VALUES,
  LIT_RPC,
} from '@lit-protocol/constants';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { ethers } from 'ethers';
import bs58 from 'bs58';

import {
  AdminConfig,
  AgentConfig,
  DEFAULT_LIT_NETWORK,
  PkpInfo,
  RegisteredTool,
  ToolPolicyRegistryConfig,
} from './types';
import { getPkpToolPolicyRegistryContract } from './utils/pkp-tool-registry';
import { LocalStorage } from './utils/storage';
import { loadPkpFromStorage, mintPkp, savePkpToStorage } from './utils/pkp';
import { FssSignerError, FssSignerErrorType } from './errors';

const DEFAULT_REGISTRY_CONFIG: ToolPolicyRegistryConfig = {
  rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
  contractAddress: '0xeCE5088AA7Ad0A6304A80Cd22B271093A5c25d5C',
} as const;

export class Admin {
  private static readonly DEFAULT_STORAGE_PATH = './.fss-signer-admin-storage';
  // TODO: Add min balance check
  // private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly litContracts: LitContracts;
  private readonly toolPolicyRegistryContract: ethers.Contract;
  private readonly adminWallet: ethers.Wallet;
  private readonly pkpInfo: PkpInfo;

  private constructor(
    litNodeClient: LitNodeClientNodeJs,
    litContracts: LitContracts,
    toolPolicyRegistryContract: ethers.Contract,
    adminWallet: ethers.Wallet,
    pkpInfo: PkpInfo
  ) {
    this.litNodeClient = litNodeClient;
    this.litContracts = litContracts;
    this.toolPolicyRegistryContract = toolPolicyRegistryContract;
    this.adminWallet = adminWallet;
    this.pkpInfo = pkpInfo;
  }

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

  public static async create(
    adminConfig: AdminConfig,
    {
      litNetwork = DEFAULT_LIT_NETWORK,
      debug = false,
      toolPolicyRegistryConfig = DEFAULT_REGISTRY_CONFIG,
    }: AgentConfig = {}
  ) {
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
      litNodeClient,
      litContracts,
      getPkpToolPolicyRegistryContract(toolPolicyRegistryConfig),
      adminWallet,
      await Admin.getPkp(litContracts, adminWallet, storage)
    );
  }

  public async transferOwnership(newOwner: string) {
    if (!this.litContracts || !this.pkpInfo) {
      throw new Error('Not properly initialized');
    }

    return this.litContracts.pkpNftContract.write[
      'safeTransferFrom(address,address,uint256)'
    ](this.adminWallet.address, newOwner, this.pkpInfo.info.tokenId);
  }

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
   * @returns Object containing arrays of tools with and without policies
   */
  public async getRegisteredTools(): Promise<{
    toolsWithPolicies: RegisteredTool[];
    toolsWithoutPolicies: string[];
  }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    // Get all permitted tools
    const permittedTools =
      await this.litContracts.pkpPermissionsContractUtils.read.getPermittedActions(
        this.pkpInfo.info.tokenId
      );

    // Convert hex CIDs to base58
    const base58PermittedTools = permittedTools.map((hexCid) => {
      // Remove '0x' prefix and convert to Buffer
      const bytes = Buffer.from(hexCid.slice(2), 'hex');
      return bs58.encode(bytes);
    });

    // Get tools with policies
    const [ipfsCids, policyData, versions] =
      await this.toolPolicyRegistryContract.getRegisteredActions(
        this.pkpInfo.info.tokenId
      );

    const toolsWithPolicies = ipfsCids.map((cid: string, i: number) => ({
      ipfsCid: cid,
      policy: policyData[i],
      version: versions[i],
    }));

    // Find tools that are permitted but don't have policies
    const toolsWithoutPolicies = base58PermittedTools.filter(
      (tool) => !ipfsCids.includes(tool)
    );

    return {
      toolsWithPolicies,
      toolsWithoutPolicies,
    };
  }

  /**
   * Get the policy for a specific tool
   * @param ipfsCid IPFS CID of the tool
   * @returns The policy and version for the tool
   */
  // TODO: Rename to getToolPolicy
  // TODO: Decode the policy bytes string to a string
  public async getToolPolicy(
    ipfsCid: string
  ): Promise<{ policy: string; version: string }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const [policy, version] =
      await this.toolPolicyRegistryContract.getActionPolicy(
        this.pkpInfo.info.tokenId,
        ipfsCid
      );

    return { policy, version };
  }

  /**
   * Set or update a policy for a specific tool
   * @param ipfsCid IPFS CID of the tool
   * @param policy Tool-specific policy bytes that must be ABI encoded
   * @param version Version of the policy
   * @returns Transaction receipt
   */
  // TODO: Rename to setToolPolicy
  // TODO: Encode the policy string to bytes
  public async setToolPolicy(ipfsCid: string, policy: string, version: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.setActionPolicy(
      this.pkpInfo.info.tokenId,
      ipfsCid,
      policy,
      version
    );

    return await tx.wait();
  }

  public async removeToolPolicy(ipfsCid: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    const tx = await this.toolPolicyRegistryContract.removeActionPolicy(
      this.pkpInfo.info.tokenId,
      ipfsCid
    );

    return await tx.wait();
  }

  /**
   * Get all delegatees for the PKP
   * @returns Array of delegatee addresses
   */
  public async getDelegatees(): Promise<string[]> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolPolicyRegistryContract.getDelegatees(
      this.pkpInfo.info.tokenId
    );
  }

  public async isDelegatee(delegatee: string) {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return await this.toolPolicyRegistryContract.isDelegateeOf(
      this.pkpInfo.info.tokenId,
      delegatee
    );
  }

  /**
   * Add a delegatee for the PKP
   * @param delegatee Address to add as delegatee
   * @returns Transaction receipt
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
   * Remove a delegatee for the PKP
   * @param delegatee Address to remove as delegatee
   * @returns Transaction receipt
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

  public async disconnect() {
    this.litNodeClient.disconnect();
  }
}
