import { LIT_NETWORK } from '@lit-protocol/constants';
import { type FssTool } from '@lit-protocol/fss-tool';
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

export interface UnknownRegisteredToolWithPolicy {
  ipfsCid: string;
  policy: string;
  version: string;
}

export interface DelegatedPkpInfo {
  tokenId: string;
  ethAddress: string;
  publicKey: string;
}

export interface IntentMatcherResponse<TParams extends Record<string, any>> {
  analysis: any;
  matchedTool: FssTool | null;
  params: {
    foundParams: Partial<TParams>;
    missingParams: Array<keyof TParams>;
    validationErrors?: Array<{ param: string; error: string }>;
  };
}

export interface IntentMatcher {
  analyzeIntentAndMatchTool(
    intent: string,
    registeredTools: FssTool<any, any>[]
  ): Promise<IntentMatcherResponse<any>>;
}

export interface CredentialStore {
  getCredentials<T>(requiredCredentialNames: readonly string[]): Promise<{
    foundCredentials: Partial<CredentialsFor<T>>;
    missingCredentials: string[];
  }>;
  setCredentials<T>(credentials: Partial<CredentialsFor<T>>): Promise<void>;
}

export type CredentialNames<T> = T extends {
  requiredCredentialNames: readonly (infer U extends string)[];
}
  ? U
  : never;

export type CredentialsFor<T> = {
  [K in CredentialNames<T>]: string;
};
