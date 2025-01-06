import { LIT_ABILITY } from '@lit-protocol/constants';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import {
  createSiweMessage,
  generateAuthSig,
  LitAccessControlConditionResource,
} from '@lit-protocol/auth-helpers';
import type {
  AuthSig,
  ExecuteJsResponse,
  JsonExecutionSdkParams,
} from '@lit-protocol/types';
import { ethers } from 'ethers';

import { DEFAULT_LIT_NETWORK, RegisteredTool, type AgentConfig } from './types';
import {
  isCapacityCreditExpired,
  loadCapacityCreditFromStorage,
  mintCapacityCredit,
  requiresCapacityCredit,
  saveCapacityCreditToStorage,
} from './utils/capacity-credit';
import { LocalStorage } from './utils/storage';
import { FssSignerError, FssSignerErrorType } from './errors';
import {
  DEFAULT_REGISTRY_CONFIG,
  getPkpToolPolicyRegistryContract,
  getRegisteredTools,
  getToolPolicy,
} from './utils/pkp-tool-registry';

export class Delegatee {
  private static readonly DEFAULT_STORAGE_PATH =
    './.fss-signer-delegatee-storage';
  // TODO: Add min balance check
  // private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly storage: LocalStorage;
  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly litContracts: LitContracts;
  private readonly toolPolicyRegistryContract: ethers.Contract;
  private readonly delegateeWallet: ethers.Wallet;

  private constructor(
    storage: LocalStorage,
    litNodeClient: LitNodeClientNodeJs,
    litContracts: LitContracts,
    toolPolicyRegistryContract: ethers.Contract,
    delegateeWallet: ethers.Wallet
  ) {
    this.storage = storage;
    this.litNodeClient = litNodeClient;
    this.litContracts = litContracts;
    this.toolPolicyRegistryContract = toolPolicyRegistryContract;
    this.delegateeWallet = delegateeWallet;
  }

  private static async getCapacityCredit(
    litContracts: LitContracts,
    storage: LocalStorage
  ) {
    if (requiresCapacityCredit(litContracts)) {
      const capacityCreditInfo = loadCapacityCreditFromStorage(storage);
      if (
        capacityCreditInfo !== null &&
        !isCapacityCreditExpired(
          capacityCreditInfo.mintedAtUtc,
          capacityCreditInfo.daysUntilUTCMidnightExpiration
        )
      ) {
        return capacityCreditInfo;
      }

      const mintMetadata = await mintCapacityCredit(litContracts);
      saveCapacityCreditToStorage(storage, mintMetadata);

      return mintMetadata;
    }

    return null;
  }

  public static async create(
    delegateePrivateKey?: string,
    {
      litNetwork = DEFAULT_LIT_NETWORK,
      debug = false,
      toolPolicyRegistryConfig = DEFAULT_REGISTRY_CONFIG,
    }: AgentConfig = {}
  ) {
    const storage = new LocalStorage(Delegatee.DEFAULT_STORAGE_PATH);

    const provider = new ethers.providers.JsonRpcProvider(
      toolPolicyRegistryConfig.rpcUrl
    );

    const storedPrivateKey = storage.getItem('privateKey');
    const _delegateePrivateKey = delegateePrivateKey || storedPrivateKey;

    if (_delegateePrivateKey === null) {
      throw new FssSignerError(
        FssSignerErrorType.DELEGATEE_MISSING_PRIVATE_KEY,
        'Delegatee private key not provided and not found in storage. Please provide a private key.'
      );
    }

    // Only save if not already stored
    if (!storedPrivateKey) {
      storage.setItem('privateKey', _delegateePrivateKey);
    }

    const delegateeWallet = new ethers.Wallet(_delegateePrivateKey, provider);

    const litNodeClient = new LitNodeClientNodeJs({
      litNetwork,
      debug,
    });
    await litNodeClient.connect();

    const litContracts = new LitContracts({
      signer: delegateeWallet,
      network: litNetwork,
      debug,
    });
    await litContracts.connect();

    // Will mint a Capacity Credit if none exists
    await Delegatee.getCapacityCredit(litContracts, storage);

    return new Delegatee(
      storage,
      litNodeClient,
      litContracts,
      getPkpToolPolicyRegistryContract(
        toolPolicyRegistryConfig,
        delegateeWallet
      ),
      delegateeWallet
    );
  }

  public async getDelegatedPkps() {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    if (!this.delegateeWallet) {
      throw new Error('Delegatee wallet not initialized');
    }

    return this.toolPolicyRegistryContract.getDelegatedPkps(
      this.delegateeWallet.address
    );
  }

  /**
   * Get all registered tools and categorize them based on whether they have policies
   * @returns Object containing arrays of tools with and without policies
   */
  public async getRegisteredToolsForPkp(pkpTokenId: string): Promise<{
    toolsWithPolicies: RegisteredTool[];
    toolsWithoutPolicies: string[];
  }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return getRegisteredTools(
      this.toolPolicyRegistryContract,
      this.litContracts,
      pkpTokenId
    );
  }

  /**
   * Get the policy for a specific tool
   * @param ipfsCid IPFS CID of the tool
   * @returns The policy and version for the tool
   */
  public async getToolPolicy(
    pkpTokenId: string,
    ipfsCid: string
  ): Promise<{ policy: string; version: string }> {
    if (!this.toolPolicyRegistryContract) {
      throw new Error('Tool policy manager not initialized');
    }

    return getToolPolicy(this.toolPolicyRegistryContract, pkpTokenId, ipfsCid);
  }

  public async executeTool(
    params: JsonExecutionSdkParams
  ): Promise<ExecuteJsResponse> {
    if (!this.litNodeClient || !this.litContracts || !this.delegateeWallet) {
      throw new Error('Delegatee not properly initialized');
    }

    const capacityCreditInfo = await Delegatee.getCapacityCredit(
      this.litContracts,
      this.storage
    );

    let capacityDelegationAuthSig: AuthSig | undefined;
    if (capacityCreditInfo !== null) {
      capacityDelegationAuthSig = (
        await this.litNodeClient.createCapacityDelegationAuthSig({
          dAppOwnerWallet: this.delegateeWallet,
          capacityTokenId: capacityCreditInfo.capacityTokenId,
          delegateeAddresses: [this.delegateeWallet.address],
          uses: '1',
        })
      ).capacityDelegationAuthSig;
    }

    const sessionSignatures = await this.litNodeClient.getSessionSigs({
      chain: 'ethereum',
      expiration: new Date(Date.now() + 1000 * 60 * 10).toISOString(), // 10 minutes
      capabilityAuthSigs:
        capacityDelegationAuthSig !== undefined
          ? [capacityDelegationAuthSig]
          : undefined,
      resourceAbilityRequests: [
        {
          resource: new LitAccessControlConditionResource('*'),
          ability: LIT_ABILITY.AccessControlConditionDecryption,
        },
      ],
      authNeededCallback: async ({
        uri,
        expiration,
        resourceAbilityRequests,
      }) => {
        const toSign = await createSiweMessage({
          uri,
          expiration,
          resources: resourceAbilityRequests,
          walletAddress: await this.delegateeWallet.getAddress(),
          nonce: await this.litNodeClient.getLatestBlockhash(),
          litNodeClient: this.litNodeClient,
        });

        return await generateAuthSig({
          signer: this.delegateeWallet,
          toSign,
        });
      },
    });

    try {
      return this.litNodeClient.executeJs({
        ...params,
        sessionSigs: sessionSignatures,
      });
    } catch (error: unknown) {
      if (error instanceof Error) {
        throw new Error(`Failed to execute tool: ${error.message}`);
      }
      throw error;
    }
  }

  public async disconnect() {
    this.litNodeClient.disconnect();
  }
}
