import { ethers } from 'ethers';
import type { AdminConfig, Policy } from '../types';
import { validateMultisigSignature } from './utils/validate-multisig-signature';

export const POLICY_ABI = [
  'function setActionPolicy(address pkp, bytes memory policy) external',
  'function getActionPolicy(address pkp, bytes32 ipfsCid) external view returns (bytes memory policy, string memory version)',
] as const;

export async function setPolicy(
  contract: ethers.Contract,
  admin: AdminConfig,
  pkpAddress: string,
  policy: Policy,
  signature?: string
): Promise<ethers.ContractTransaction> {
  if (admin.type === 'multisig' && !signature) {
    throw new Error('Signature required for multisig admin');
  }

  const policyData = ethers.utils.defaultAbiCoder.encode(
    ['string', 'bytes', 'string'],
    [policy.type, policy.value, policy.version]
  );

  if (admin.type === 'multisig') {
    // Validate multisig signature using EIP-1271
    const isValid = await validateMultisigSignature(
      admin.address,
      policyData,
      signature!,
      contract.provider
    );

    if (!isValid) {
      throw new Error('Invalid multisig signature');
    }
  }

  return await contract.setActionPolicy(pkpAddress, policyData);
}

export async function getPolicy(
  contract: ethers.Contract,
  pkpAddress: string,
  ipfsCid: string
): Promise<{ policy: Policy | null; version: string }> {
  try {
    const [policyData, version] = await contract.getActionPolicy(
      pkpAddress,
      ethers.utils.id(ipfsCid)
    );

    if (policyData === '0x' || version === '') {
      return { policy: null, version: '' };
    }

    const [type, value, policyVersion] = ethers.utils.defaultAbiCoder.decode(
      ['string', 'bytes', 'string'],
      policyData
    );

    return {
      policy: { type, value, version: policyVersion },
      version,
    };
  } catch (error) {
    console.error('Error fetching policy:', error);
    return { policy: null, version: '' };
  }
}
