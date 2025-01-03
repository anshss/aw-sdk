import { ethers } from 'ethers';
import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import { LIT_NETWORK, LIT_RPC } from '@lit-protocol/constants';
import type {
  AgentConfig,
  AdminConfig,
  AgentAdmin,
  Policy,
  ToolPolicyRegistryConfig,
} from '../types';
import { loadPkp } from './pkp';
import { setPolicy, getPolicy, POLICY_ABI } from './policy-manager';
import { getDelegatees, setDelegatees } from './delegatees';

const DEFAULT_REGISTRY_CONFIG: ToolPolicyRegistryConfig = {
  rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
  contractAddress: '0xD78e1C1183A29794A092dDA7dB526A91FdE36020',
} as const;

export class Admin implements AgentAdmin {
  private static readonly MIN_BALANCE = ethers.utils.parseEther('0.01');

  public readonly pkpInfo;
  public readonly litClient;
  public readonly wallet;
  public readonly policyContract;
  public readonly config;

  private constructor(
    pkpInfo: AgentAdmin['pkpInfo'],
    litClient: AgentAdmin['litClient'],
    wallet: AgentAdmin['wallet'],
    policyContract: AgentAdmin['policyContract'],
    config: AgentAdmin['config']
  ) {
    this.pkpInfo = pkpInfo;
    this.litClient = litClient;
    this.wallet = wallet;
    this.policyContract = policyContract;
    this.config = config;
  }

  private async checkMinBalance(operation: string): Promise<void> {
    const balance = await this.wallet.getBalance();
    if (balance.lt(Admin.MIN_BALANCE)) {
      throw new Error(
        `Insufficient balance: Admin wallet does not have enough tokens to ${operation}`
      );
    }
  }

  public static async create(
    adminConfig: AdminConfig,
    agentConfig: AgentConfig = {}
  ): Promise<Admin> {
    // Initialize Lit Node Client
    const litClient = new LitNodeClientNodeJs({
      litNetwork: agentConfig.litNetwork ?? LIT_NETWORK.DatilTest,
      debug: agentConfig.debug,
    });
    await litClient.connect();

    const registryConfig =
      agentConfig.toolPolicyRegistryConfig ?? DEFAULT_REGISTRY_CONFIG;
    const provider = new ethers.providers.JsonRpcProvider(
      registryConfig.rpcUrl
    );

    // Create wallet based on admin type
    let wallet: ethers.Wallet;
    if (adminConfig.type === 'eoa') {
      wallet = new ethers.Wallet(adminConfig.privateKey, provider);
    } else {
      // For multisig, we don't need a wallet as it will use the contract interface
      throw new Error('Multisig admin implementation pending');
    }

    const policyContract = new ethers.Contract(
      registryConfig.contractAddress,
      POLICY_ABI,
      provider
    );

    const pkpInfo = loadPkp(localStorage);

    return new Admin(pkpInfo, litClient, wallet, policyContract, adminConfig);
  }

  public async setPolicy(
    pkpAddress: string,
    policy: Policy,
    signature?: string
  ): Promise<ethers.ContractTransaction> {
    await this.checkMinBalance('set a new policy');
    return await setPolicy(
      this.policyContract,
      this.config,
      pkpAddress,
      policy,
      signature
    );
  }

  public async getPolicy(
    pkpAddress: string,
    ipfsCid: string
  ): Promise<{ policy: Policy | null; version: string }> {
    return await getPolicy(this.policyContract, pkpAddress, ipfsCid);
  }

  public async setDelegatees(
    pkpAddress: string,
    delegatees: string[],
    signature?: string
  ): Promise<ethers.ContractTransaction> {
    await this.checkMinBalance('set new delegatees');
    return await setDelegatees(
      this.policyContract,
      this.config,
      pkpAddress,
      delegatees,
      signature
    );
  }

  public async getDelegatees(pkpAddress: string): Promise<string[]> {
    return await getDelegatees(this.policyContract, pkpAddress);
  }
}
