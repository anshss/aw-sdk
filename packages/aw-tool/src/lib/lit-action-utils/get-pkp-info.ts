import { NETWORK_CONFIG } from './network-config';

/**
 * Retrieves detailed information about a PKP (Programmable Key Pair) using its Ethereum address.
 * This function queries the PubkeyRouter contract to fetch the PKP's token ID and public key.
 * 
 * @param pkpEthAddress - The Ethereum address associated with the PKP.
 * @returns A promise that resolves to an object containing:
 *   - tokenId: The PKP's token ID as a string
 *   - ethAddress: The input Ethereum address
 *   - publicKey: The PKP's public key
 * @throws Error if the current Lit network is not supported.
 */
export const getPkpInfo = async (pkpEthAddress: string) => {
  console.log('Getting PKP info from PubkeyRouter...');

  // Get PubkeyRouter address for current network
  const networkConfig =
    NETWORK_CONFIG[LIT_NETWORK as keyof typeof NETWORK_CONFIG];
  if (!networkConfig) {
    throw new Error(`Unsupported Lit network: ${LIT_NETWORK}`);
  }

  const PUBKEY_ROUTER_ABI = [
    'function ethAddressToPkpId(address ethAddress) public view returns (uint256)',
    'function getPubkey(uint256 tokenId) public view returns (bytes memory)',
  ];

  const pubkeyRouter = new ethers.Contract(
    networkConfig.pubkeyRouterAddress,
    PUBKEY_ROUTER_ABI,
    new ethers.providers.JsonRpcProvider(
      await Lit.Actions.getRpcUrl({
        chain: 'yellowstone',
      })
    )
  );

  // Get PKP ID from eth address
  console.log(`Getting PKP ID for eth address ${pkpEthAddress}...`);
  const pkpTokenId = await pubkeyRouter.ethAddressToPkpId(pkpEthAddress);
  console.log(`Got PKP token ID: ${pkpTokenId}`);

  // Get public key from PKP ID
  console.log(`Getting public key for PKP ID ${pkpTokenId}...`);
  const publicKey = await pubkeyRouter.getPubkey(pkpTokenId);
  console.log(`Got public key: ${publicKey}`);

  return {
    tokenId: pkpTokenId.toString(),
    ethAddress: pkpEthAddress,
    publicKey,
  };
};
