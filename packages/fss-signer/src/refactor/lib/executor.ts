import { ethers } from 'ethers';
import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import { LIT_NETWORK, LIT_RPC } from '@lit-protocol/constants';
import type {
  AgentConfig,
  AgentExecutor,
  ToolPolicyRegistryConfig,
} from '../types';
import { loadPkp } from './pkp';
import { POLICY_ABI } from './policy-manager';
import { getDelegatees } from './delegatees';

const DEFAULT_REGISTRY_CONFIG: ToolPolicyRegistryConfig = {
  rpcUrl: LIT_RPC.CHRONICLE_YELLOWSTONE,
  contractAddress: '0xD78e1C1183A29794A092dDA7dB526A91FdE36020',
} as const;

export class Executor implements AgentExecutor {
  public readonly pkpInfo;
  public readonly litClient;
  public readonly wallet;
  public readonly policyContract;

  private constructor(
    pkpInfo: AgentExecutor['pkpInfo'],
    litClient: AgentExecutor['litClient'],
    wallet: AgentExecutor['wallet'],
    policyContract: AgentExecutor['policyContract']
  ) {
    this.pkpInfo = pkpInfo;
    this.litClient = litClient;
    this.wallet = wallet;
    this.policyContract = policyContract;
  }

  public static async create(
    executorPrivateKey: string,
    agentConfig: AgentConfig = {}
  ): Promise<Executor> {
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
    const wallet = new ethers.Wallet(executorPrivateKey, provider);

    const policyContract = new ethers.Contract(
      registryConfig.contractAddress,
      POLICY_ABI,
      provider
    );

    const pkpInfo = loadPkp(localStorage);

    return new Executor(pkpInfo, litClient, wallet, policyContract);
  }

  private async validateExecutor(
    pkpAddress: string,
    executorAddress: string
  ): Promise<boolean> {
    try {
      const delegatees = await getDelegatees(this.policyContract, pkpAddress);
      return delegatees.includes(executorAddress);
    } catch (error) {
      console.error('Error validating executor:', error);
      return false;
    }
  }

  private async getSessionSigs(chain: string): Promise<any> {
    return await this.litClient.getSessionSigs({
      chain,
      resources: ['*'],
      switchChain: false,
      expiration: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      sessionKey: this.wallet,
    });
  }

  public async executeLitAction(params: {
    ipfsCid: string;
    jsParams: Record<string, unknown>;
  }): Promise<any> {
    if (!this.pkpInfo) {
      throw new Error('PKP not found');
    }

    // Validate executor
    const isValidExecutor = await this.validateExecutor(
      this.pkpInfo.ethAddress,
      this.wallet.address
    );

    if (!isValidExecutor) {
      throw new Error('Invalid executor');
    }

    // Get session signatures
    const sessionSigs = await this.getSessionSigs('ethereum');

    // Execute
    return await this.litClient.executeJs({
      ipfsId: params.ipfsCid,
      sessionSigs,
      jsParams: {
        ...params.jsParams,
        executorAddress: this.wallet.address,
      },
    });
  }
}
