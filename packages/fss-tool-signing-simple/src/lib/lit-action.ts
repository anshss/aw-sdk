declare global {
  // Injected By Lit
  const Lit: any;
  const LitAuth: any;
  const ethers: {
    providers: {
      JsonRpcProvider: any;
    };
    utils: {
      Interface: any;
      parseUnits: any;
      defaultAbiCoder: any;
      keccak256: any;
      toUtf8Bytes: any;
      arrayify: any;
      getAddress: any;
    };
    Wallet: any;
    Contract: any;
  };

  const pkp: {
    ethAddress: string;
    publicKey: string;
    tokenId: string;
  };

  // Required Inputs
  const params: {
    message: string;
  };
}

export default async () => {
  try {

    async function checkLitAuthAddressIsDelegatee(
      pkpToolRegistryContract: any
    ) {
      console.log(
        `Checking if Lit Auth address: ${LitAuth.authSigAddress} is a delegatee for PKP ${pkp.tokenId}...`
      );

      // Check if the session signer is a delegatee
      const sessionSigner = ethers.utils.getAddress(LitAuth.authSigAddress);
      const isDelegatee = await pkpToolRegistryContract.isDelegateeOf(
        pkp.tokenId,
        sessionSigner
      );

      if (!isDelegatee) {
        throw new Error(
          `Session signer ${sessionSigner} is not a delegatee for PKP ${pkp.tokenId}`
        );
      }

      console.log(
        `Session signer ${sessionSigner} is a delegatee for PKP ${pkp.tokenId}`
      );
    }

    async function validateInputsAgainstPolicy(
      pkpToolRegistryContract: any,
    ) {
      console.log(`Validating inputs against policy...`);

      // Get policy for this tool
      const TOOL_IPFS_CID = LitAuth.actionIpfsIds[0];
      console.log(`Getting policy for tool ${TOOL_IPFS_CID}...`);
      const [policyData] = await pkpToolRegistryContract.getToolPolicy(
        pkp.tokenId,
        TOOL_IPFS_CID
      );

      if (policyData === '0x') {
        console.log(
          `No policy found for tool ${TOOL_IPFS_CID} on PKP ${pkp.tokenId}`
        );
        return;
      }

      // Decode policy
      console.log(`Decoding policy...`);
      const decodedPolicy = ethers.utils.defaultAbiCoder.decode(
        [
          'tuple(string[] allowedPrefixes)',
        ],
        policyData
      )[0];

      // Validate message prefix
      if (
        !decodedPolicy.allowedPrefixes.some((prefix: string) => params.message.startsWith(prefix))
      ) {
        throw new Error(
          `Message does not start with any allowed prefix. Allowed prefixes: ${decodedPolicy.allowedPrefixes.join(
            ', '
          )}`
        );
      }

      console.log(`Inputs validated against policy`);
    }

    async function signMessage(message: string) {
      const pkForLit = pkp.publicKey.startsWith("0x")
        ? pkp.publicKey.slice(2)
        : pkp.publicKey;

      const sig = await Lit.Actions.signEcdsa({
        toSign: ethers.utils.arrayify(
          ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message))
        ),
        publicKey: pkForLit,
        sigName: 'sig',
      });

      return sig;
    }

    const PKP_TOOL_REGISTRY_ABI = [
      'function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool)',
      'function getToolPolicy(uint256 pkpTokenId, string calldata ipfsCid) external view returns (bytes memory policy, string memory version)',
    ];
    const PKP_TOOL_REGISTRY = '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F';
    const pkpToolRegistryContract = new ethers.Contract(
      PKP_TOOL_REGISTRY,
      PKP_TOOL_REGISTRY_ABI,
      new ethers.providers.JsonRpcProvider(
        await Lit.Actions.getRpcUrl({
          chain: 'yellowstone',
        })
      )
    );

    await checkLitAuthAddressIsDelegatee(pkpToolRegistryContract);
    await validateInputsAgainstPolicy(
      pkpToolRegistryContract
    );

    await signMessage(params.message);

    // Return the signature
    Lit.Actions.setResponse({
      response: JSON.stringify({
        response: "Signed message!",
        status: 'success',
      }),
    });
  } catch (err: any) {
    console.error('Error:', err);
    Lit.Actions.setResponse({
      response: JSON.stringify({
        status: 'error',
        error: err.message || String(err),
      }),
    });
  }
};
