import { ethers } from 'ethers';
import type { LIT_NETWORKS_KEYS, ILitNodeClient } from '@lit-protocol/types';

export interface ToolPolicyRegistryConfig {
  rpcUrl: string;
  contractAddress: string;
}

export interface AgentConfig {
  litNetwork?: LIT_NETWORKS_KEYS;
  debug?: boolean;
  toolPolicyRegistryConfig?: ToolPolicyRegistryConfig;
}

interface BaseAdminConfig {
  address: string;
}

interface EoaAdminConfig extends BaseAdminConfig {
  type: 'eoa';
  privateKey: string;
}

interface MultisigAdminConfig extends BaseAdminConfig {
  type: 'multisig';
  abi: string;
}

export type AdminConfig = EoaAdminConfig | MultisigAdminConfig;

export interface PkpInfo {
  tokenId: string;
  publicKey: string;
  ethAddress: string;
}

// Base interface with common properties
interface BaseAgent {
  pkpInfo: PkpInfo | null;
  litClient: ILitNodeClient;
  policyContract: ethers.Contract;
}

// Admin interface for managing agent policies and delegations
export interface AgentAdmin extends BaseAgent {
  wallet: ethers.Wallet;
  config: AdminConfig;

  // Admin methods
  setPolicy(
    pkpAddress: string,
    policy: Policy,
    signature?: string
  ): Promise<ethers.ContractTransaction>;

  getPolicy(
    pkpAddress: string,
    ipfsCid: string
  ): Promise<{ policy: Policy | null; version: string }>;

  setDelegatees(
    pkpAddress: string,
    delegatees: string[],
    signature?: string
  ): Promise<ethers.ContractTransaction>;

  getDelegatees(pkpAddress: string): Promise<string[]>;
}

// Executor interface for running agent actions
export interface AgentExecutor extends BaseAgent {
  wallet: ethers.Wallet;
}

export interface ExecutionContext {
  litClient: ILitNodeClient;
  wallet: ethers.Wallet;
  pkpInfo: PkpInfo | null;
}

export interface Policy {
  type: string;
  value: any;
  version: string;
}

export interface CapacityCreditMintOptions {
  amount?: number;
  duration?: number;
}
