import { LitContracts } from '@lit-protocol/contracts-sdk';
import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import type { AuthSig } from '@lit-protocol/types';
import { LIT_NETWORK } from '@lit-protocol/constants';
import { ethers } from 'ethers';

import { LocalStorage } from './storage';
import {
  CapacityCreditMintOptions,
  CapacityCreditDelegationAuthSigOptions,
  CapacityCreditInfo,
} from './types';
import { FssSignerError, FssSignerErrorType } from './errors';

/**
 * Load capacity credit ID from storage
 */
export function loadCapacityCreditFromStorage(
  storage: LocalStorage
): CapacityCreditInfo | null {
  try {
    const capacityCredit = storage.getItem('capacityCredit');
    if (capacityCredit) {
      return JSON.parse(capacityCredit) as CapacityCreditInfo;
    }
  } catch (error) {
    throw new FssSignerError(
      FssSignerErrorType.STORAGE_FAILED_TO_GET_ITEM,
      'Failed to retrieve capacity credit from storage',
      {
        details: error,
      }
    );
  }
  return null;
}

export function saveCapacityCreditToStorage(
  storage: LocalStorage,
  capacityCreditInfo: CapacityCreditInfo
) {
  storage.setItem('capacityCredit', JSON.stringify(capacityCreditInfo));
}

/**
 * Check if the current network requires capacity credits
 */
export function requiresCapacityCredit(litContracts: LitContracts): boolean {
  return (
    litContracts.network === LIT_NETWORK.DatilTest ||
    litContracts.network === LIT_NETWORK.Datil
  );
}

export function isCapacityCreditExpired(
  mintedAtUtc: string,
  daysUntilUTCMidnightExpiration: number
): boolean {
  // Create dates from UTC timestamps
  const now = new Date();
  const mintedDate = new Date(mintedAtUtc);

  // Calculate the expiration date at UTC midnight
  const expirationDate = new Date(mintedDate);
  expirationDate.setUTCDate(
    mintedDate.getUTCDate() + daysUntilUTCMidnightExpiration
  );
  expirationDate.setUTCHours(0, 0, 0, 0); // Set to UTC midnight

  // Expire 10 minutes before UTC midnight
  const earlyExpirationMinutes = 10;
  const earlyExpirationMilliseconds = earlyExpirationMinutes * 60 * 1000;

  // Compare timestamps in UTC
  return now.getTime() > expirationDate.getTime() - earlyExpirationMilliseconds;
}

/**
 * Mint a new capacity credit NFT
 */
export async function mintCapacityCredit(
  litContracts: LitContracts,
  {
    requestsPerKilosecond = 10,
    daysUntilUTCMidnightExpiration = 1,
  }: CapacityCreditMintOptions = {}
): Promise<CapacityCreditInfo> {
  // Calculate expiration timestamp at UTC midnight
  const now = new Date();
  const expirationDate = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate() + daysUntilUTCMidnightExpiration,
      0,
      0,
      0,
      0 // Set to midnight UTC
    )
  );
  const expiresAt = Math.floor(expirationDate.getTime() / 1000); // Convert to Unix timestamp

  const mintCost = await litContracts.rateLimitNftContract.read.calculateCost(
    requestsPerKilosecond,
    expiresAt
  );

  if (mintCost.gt(await litContracts.signer.getBalance())) {
    throw new FssSignerError(
      FssSignerErrorType.INSUFFICIENT_BALANCE_CAPACITY_CREDIT_MINT,
      `${await litContracts.signer.getAddress()} has insufficient balance to mint capacity credit: ${ethers.utils.formatEther(
        await litContracts.signer.getBalance()
      )} < ${ethers.utils.formatEther(mintCost)}`
    );
  }

  const capacityCreditInfo = await litContracts.mintCapacityCreditsNFT({
    requestsPerKilosecond,
    daysUntilUTCMidnightExpiration,
  });

  return {
    capacityTokenIdStr: capacityCreditInfo.capacityTokenIdStr,
    capacityTokenId: capacityCreditInfo.capacityTokenId,
    requestsPerKilosecond,
    daysUntilUTCMidnightExpiration,
    mintedAtUtc: new Date().toISOString(),
  };
}
