import { ethers } from 'ethers';

/**
 * Validates a signature using EIP-1271 standard for smart contract wallets
 */
export async function validateMultisigSignature(
  multisigAddress: string,
  data: string,
  signature: string,
  provider: ethers.providers.Provider
): Promise<boolean> {
  const EIP1271_ABI = [
    'function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4)',
  ];
  const EIP1271_MAGIC_VALUE = '0x1626ba7e';

  const multisig = new ethers.Contract(multisigAddress, EIP1271_ABI, provider);

  try {
    const result = await multisig.isValidSignature(
      ethers.utils.hashMessage(data),
      signature
    );
    return result === EIP1271_MAGIC_VALUE;
  } catch (error) {
    console.error('Signature validation failed:', error);
    return false;
  }
}
