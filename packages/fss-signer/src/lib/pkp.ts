import type { LitContracts } from '@lit-protocol/contracts-sdk';
import { ethers } from 'ethers';

import type { LocalStorage } from './storage';
import { PkpInfo } from './types';
import { FssSignerError, FssSignerErrorType } from './errors';

export function loadPkpFromStorage(storage: LocalStorage): PkpInfo | null {
  try {
    const pkp = storage.getItem('pkp');
    if (pkp) {
      return JSON.parse(pkp) as PkpInfo;
    }
  } catch (error) {
    throw new FssSignerError(
      FssSignerErrorType.STORAGE_FAILED_TO_GET_ITEM,
      'Failed to retrieve PKP from storage',
      {
        details: error,
      }
    );
  }
  return null;
}

export function savePkpToStorage(storage: LocalStorage, pkpInfo: PkpInfo) {
  storage.setItem('pkp', JSON.stringify(pkpInfo));
}

export async function mintPkp(
  litContracts: LitContracts,
  wallet: ethers.Wallet
): Promise<PkpInfo> {
  const mintCost = await litContracts.pkpNftContract.read.mintCost();
  if (mintCost.gt(await wallet.getBalance())) {
    throw new FssSignerError(
      FssSignerErrorType.INSUFFICIENT_BALANCE_PKP_MINT,
      `${await wallet.getAddress()} has insufficient balance to mint PKP: ${ethers.utils.formatEther(
        await wallet.getBalance()
      )} < ${ethers.utils.formatEther(mintCost)}`
    );
  }

  const mintMetadata = await litContracts.pkpNftContractUtils.write.mint();

  return {
    info: mintMetadata.pkp,
    mintTx: mintMetadata.tx,
    mintReceipt: mintMetadata.res,
  };
}
