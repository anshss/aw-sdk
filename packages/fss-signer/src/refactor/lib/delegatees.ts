import { ethers } from 'ethers';
import type { AdminConfig } from '../types';
import { validateMultisigSignature } from './utils/validate-multisig-signature';

export async function setDelegatees(
  contract: ethers.Contract,
  admin: AdminConfig,
  pkpAddress: string,
  delegatees: string[],
  signature?: string
): Promise<ethers.ContractTransaction> {
  if (admin.type === 'multisig' && !signature) {
    throw new Error('Signature required for multisig admin');
  }

  if (admin.type === 'multisig') {
    // Validate multisig signature
    const isValid = await validateMultisigSignature(
      admin.address,
      delegatees.join(','),
      signature!,
      contract.provider
    );

    if (!isValid) {
      throw new Error('Invalid multisig signature');
    }
  }

  return await contract.setDelegatees(pkpAddress, delegatees);
}

export async function getDelegatees(
  contract: ethers.Contract,
  pkpAddress: string
): Promise<string[]> {
  try {
    return await contract.getDelegatees(pkpAddress);
  } catch (error) {
    console.error('Error getting delegatees:', error);
    return [];
  }
}
