import { NETWORK_CONFIG } from './network-config';

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
