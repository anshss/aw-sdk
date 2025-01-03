import { ethers } from 'ethers';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import type { SigResponse } from '@lit-protocol/types';
import type { PkpInfo, CapacityCreditMintOptions } from '../types';

interface Storage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

interface SignParams {
  toSign: string;
  sessionSigs: any;
  litNodeClient: any;
}

const PKP_INFO_KEY = 'lit-pkp-info';

export function loadPkp(storage: Storage): PkpInfo | null {
  try {
    const pkpInfo = storage.getItem(PKP_INFO_KEY);
    return pkpInfo ? JSON.parse(pkpInfo) : null;
  } catch (error) {
    console.error('Error loading PKP info:', error);
    return null;
  }
}

export function savePkp(storage: Storage, pkpInfo: PkpInfo): void {
  try {
    storage.setItem(PKP_INFO_KEY, JSON.stringify(pkpInfo));
  } catch (error) {
    console.error('Error saving PKP info:', error);
  }
}

export function clearStoredPkp(storage: Storage): void {
  try {
    storage.removeItem(PKP_INFO_KEY);
  } catch (error) {
    console.error('Error clearing PKP info:', error);
  }
}

export function pkpSign({
  toSign,
  sessionSigs,
  litNodeClient,
}: SignParams): Promise<SigResponse> {
  if (!litNodeClient) {
    throw new Error('Lit client not initialized');
  }

  const pkpInfo = loadPkp(localStorage);
  if (!pkpInfo) {
    throw new Error('PKP not found');
  }

  return litNodeClient.pkpSign({
    pubKey: pkpInfo.publicKey,
    sessionSigs,
    toSign: ethers.utils.arrayify(toSign),
  });
}
