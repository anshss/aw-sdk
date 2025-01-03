import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import { LIT_NETWORK, LIT_RPC } from '@lit-protocol/constants';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { ethers } from 'ethers';

import {
  AdminConfig,
  AgentConfig,
  CapacityCreditInfo,
  PkpInfo,
  ToolPolicyRegistryConfig,
} from './types';
import { getPkpToolPolicyRegistryContract } from './pkp-tool-registry';
import { LocalStorage } from './storage';
import { loadPkpFromStorage, mintPkp, savePkpToStorage } from './pkp';
import { Storage } from 'src/lib/storage';
import {
  isCapacityCreditExpired,
  loadCapacityCreditFromStorage,
  requiresCapacityCredit,
  saveCapacityCreditToStorage,
} from './capacity-credit';
import { mintCapacityCredit } from './capacity-credit';

const DEFAULT_REGISTRY_CONFIG: ToolPolicyRegistryConfig = {
  rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
  contractAddress: '0xD78e1C1183A29794A092dDA7dB526A91FdE36020',
} as const;

export class Admin {
  private static readonly DEFAULT_LIT_NETWORK = LIT_NETWORK.DatilTest;
  private static readonly MIN_BALANCE = ethers.utils.parseEther('0.001');

  private readonly storage: Storage;
  private readonly litNodeClient: LitNodeClientNodeJs;
  private readonly toolPolicyRegistryContract: ethers.Contract;
  private readonly adminWallet: ethers.Wallet;
  private readonly pkpInfo: PkpInfo;

  private capacityCreditInfo: CapacityCreditInfo | null;

  private constructor(
    storage: Storage,
    litNodeClient: LitNodeClientNodeJs,
    toolPolicyRegistryContract: ethers.Contract,
    adminWallet: ethers.Wallet,
    pkpInfo: PkpInfo,
    capacityCreditInfo: CapacityCreditInfo | null
  ) {
    this.storage = storage;
    this.litNodeClient = litNodeClient;
    this.toolPolicyRegistryContract = toolPolicyRegistryContract;
    this.adminWallet = adminWallet;
    this.pkpInfo = pkpInfo;
    this.capacityCreditInfo = capacityCreditInfo;
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
    adminConfig: AdminConfig,
    {
      litNetwork = Admin.DEFAULT_LIT_NETWORK,
      debug = false,
      toolPolicyRegistryConfig = DEFAULT_REGISTRY_CONFIG,
    }: AgentConfig = {}
  ) {
    const storage = new LocalStorage();

    const litNodeClient = new LitNodeClientNodeJs({
      litNetwork,
      debug,
    });
    await litNodeClient.connect();

    const provider = new ethers.providers.JsonRpcProvider(
      toolPolicyRegistryConfig.rpcUrl
    );
    let adminWallet: ethers.Wallet;
    if (adminConfig.type === 'eoa') {
      adminWallet = new ethers.Wallet(adminConfig.privateKey, provider);
    } else {
      throw new Error('Multisig admin not implemented');
    }

    const litContracts = new LitContracts({
      signer: adminWallet,
      network: litNetwork,
      debug,
    });
    await litContracts.connect();

    return new Admin(
      storage,
      litNodeClient,
      getPkpToolPolicyRegistryContract(toolPolicyRegistryConfig),
      adminWallet,
      await Admin.getPkp(litContracts, adminWallet, storage),
      await Admin.getCapacityCredit(litContracts, storage)
    );
  }

  public async getRegisteredTools() {}

  public async getToolPolicy() {}

  public async setToolPolicy() {}

  public async getPkpsDelegatees() {}

  public async addPkpDelegatee() {}

  public async removePkpDelegatee() {}
}
