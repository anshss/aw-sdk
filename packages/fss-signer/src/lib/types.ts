import { LIT_NETWORK } from '@lit-protocol/constants';
import type { ethers } from 'ethers';

export type LitNetwork =
  | (typeof LIT_NETWORK)['DatilDev']
  | (typeof LIT_NETWORK)['DatilTest']
  | (typeof LIT_NETWORK)['Datil'];

export interface ToolPolicyRegistryConfig {
  rpcUrl: string;
  contractAddress: string;
}

export interface AgentConfig {
  litNetwork?: LitNetwork;
  debug?: boolean;
  toolPolicyRegistryConfig?: ToolPolicyRegistryConfig;
}

interface EoaAdminConfig {
  type: 'eoa';
  privateKey?: string;
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

export interface DelegatedPkpInfo {
  tokenId: string;
  ethAddress: string;
  publicKey: string;
}
