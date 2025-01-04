import { LIT_NETWORK } from '@lit-protocol/constants';
import type { LIT_NETWORKS_KEYS } from '@lit-protocol/types';
import type { ethers } from 'ethers';

export const DEFAULT_LIT_NETWORK = LIT_NETWORK.DatilTest;

export interface ToolPolicyRegistryConfig {
  rpcUrl: string;
  contractAddress: string;
}

export interface AgentConfig {
  litNetwork?: LIT_NETWORKS_KEYS;
  debug?: boolean;
  toolPolicyRegistryConfig?: ToolPolicyRegistryConfig;
}

interface EoaAdminConfig {
  type: 'eoa';
  privateKey: string;
}

interface MultisigAdminConfig {
  type: 'multisig';
  address: string;
  abi: string;
}

export type AdminConfig = EoaAdminConfig | MultisigAdminConfig;

export interface PkpInfo {
  info: {
    tokenId: string;
    publicKey: string;
    ethAddress: string;
  };
  mintTx: ethers.ContractTransaction;
  mintReceipt: ethers.ContractReceipt;
}

export interface CapacityCreditInfo {
  capacityTokenIdStr: string;
  capacityTokenId: string;
  requestsPerKilosecond: number;
  daysUntilUTCMidnightExpiration: number;
  mintedAtUtc: string;
}

export interface CapacityCreditDelegationAuthSigOptions {
  delegateeAddresses: string[];
  uses?: string;
  expiration?: string;
}

export interface CapacityCreditMintOptions {
  requestsPerKilosecond?: number;
  daysUntilUTCMidnightExpiration?: number;
}

export interface RegisteredTool {
  ipfsCid: string;
  policy: string;
  version: string;
}
