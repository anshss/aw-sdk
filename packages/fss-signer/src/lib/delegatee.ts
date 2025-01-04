import { LIT_ABILITY, LIT_RPC } from '@lit-protocol/constants';
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

import { DEFAULT_LIT_NETWORK, type AgentConfig } from './types';
import {
  isCapacityCreditExpired,
  loadCapacityCreditFromStorage,
  mintCapacityCredit,
  requiresCapacityCredit,
  saveCapacityCreditToStorage,
} from './utils/capacity-credit';
import { LocalStorage } from './utils/storage';

export class Delegatee {
  private static readonly DEFAULT_STORAGE_PATH =
    './.fss-signer-delegatee-storage';
  private static readonly DEFAULT_RPC_URL = LIT_RPC.CHRONICLE_YELLOWSTONE;
  // TODO: Add min balance check
  // private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly storage: LocalStorage;
  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly litContracts: LitContracts;
  private readonly delegateeWallet: ethers.Wallet;

  private constructor(
    storage: LocalStorage,
    litNodeClient: LitNodeClientNodeJs,
    litContracts: LitContracts,
    delegateeWallet: ethers.Wallet
  ) {
    this.storage = storage;
    this.litNodeClient = litNodeClient;
    this.litContracts = litContracts;
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
    delegateePrivateKey: string,
    {
      litNetwork = DEFAULT_LIT_NETWORK,
      debug = false,
    }: Omit<AgentConfig, 'toolPolicyRegistryConfig'> = {}
  ) {
    const storage = new LocalStorage(Delegatee.DEFAULT_STORAGE_PATH);

    const litNodeClient = new LitNodeClientNodeJs({
      litNetwork,
      debug,
    });
    await litNodeClient.connect();

    const delegateeWallet = new ethers.Wallet(
      delegateePrivateKey,
      new ethers.providers.JsonRpcProvider(Delegatee.DEFAULT_RPC_URL)
    );

    const litContracts = new LitContracts({
      signer: delegateeWallet,
      network: litNetwork,
      debug,
    });
    await litContracts.connect();

    // Will mint a Capacity Credit if none exists
    await Delegatee.getCapacityCredit(litContracts, storage);

    return new Delegatee(storage, litNodeClient, litContracts, delegateeWallet);
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
}
