declare global {
  // Injected By Lit
  const Lit: any; // Lit SDK instance for interacting with Lit Protocol
  const LitAuth: any; // Lit Auth instance for authentication and session management
  const ethers: {
    providers: {
      JsonRpcProvider: any; // Ethers.js provider for JSON-RPC connections
    };
    utils: {
      Interface: any; // Utility for encoding/decoding contract ABI
      parseUnits: any; // Converts a string representation of tokens to the smallest unit (e.g., wei)
      formatUnits: any; // Converts token amounts from smallest unit to a readable format
      formatEther: any; // Converts wei to ether
      arrayify: any; // Converts a hex string to a byte array
      keccak256: any; // Computes the Keccak-256 hash of the input
      serializeTransaction: any; // Serializes a transaction object into a hex string
      joinSignature: any; // Combines signature components (r, s, v) into a single signature
      isHexString: any; // Checks if a string is a valid hex string
      getAddress: any; // Normalizes an Ethereum address to checksum format
      defaultAbiCoder: any; // Encodes/decodes data according to the ABI specification
    };
    BigNumber: any; // Utility for handling large numbers
    Contract: any; // Ethers.js contract abstraction
  };

  // Injected by build script
  const LIT_NETWORK: string; // The Lit network being used (e.g., 'datil', 'datil-dev')
  const PKP_TOOL_REGISTRY_ADDRESS: string; // Address of the PKP Tool Registry contract

  // Required Inputs
  const params: {
    pkpEthAddress: string; // Ethereum address of the PKP (Programmable Key Pair)
    rpcUrl: string; // RPC URL for the blockchain network
    chainId: string; // Chain ID of the blockchain network
    tokenIn: string; // Address of the input token for the swap
    tokenOut: string; // Address of the output token for the swap
    amountIn: string; // Amount of input token to swap
  };
}

type JsonRpcProvider = ReturnType<typeof ethers.providers.JsonRpcProvider>;

export default async () => {
  try {
    let UNISWAP_V3_QUOTER: string; // Address of the Uniswap V3 Quoter contract
    let UNISWAP_V3_ROUTER: string; // Address of the Uniswap V3 Router contract
    switch (params.chainId) {
      case '8453': // Base chain
        UNISWAP_V3_QUOTER = '0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a';
        UNISWAP_V3_ROUTER = '0x2626664c2603336E57B271c5C0b26F421741e481';
        break;
      case '1': // Ethereum mainnet
      case '42161': // Arbitrum
        UNISWAP_V3_QUOTER = '0x61fFE014bA17989E743c5F6cB21bF9697530B21e';
        UNISWAP_V3_ROUTER = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45';
        break;
      default:
        throw new Error(`Unsupported chain ID: ${params.chainId}`);
    }

    /**
     * Fetches PKP (Programmable Key Pair) information from the PubkeyRouter contract.
     * @returns {Promise<{ tokenId: string, ethAddress: string, publicKey: string }>} PKP information.
     */
    async function getPkpInfo() {
      console.log('Getting PKP info from PubkeyRouter...');

      // Get PubkeyRouter address for the current network
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

      // Get PKP ID from the Ethereum address
      console.log(`Getting PKP ID for eth address ${params.pkpEthAddress}...`);
      const pkpTokenId = await pubkeyRouter.ethAddressToPkpId(
        params.pkpEthAddress
      );
      console.log(`Got PKP token ID: ${pkpTokenId}`);

      // TODO: Implement this check
      // if (pkpTokenId.isZero()) {
      //   throw new Error(`No PKP found for eth address ${params.pkpEthAddress}`);
      // }

      // Get public key from the PKP ID
      console.log(`Getting public key for PKP ID ${pkpTokenId}...`);
      const publicKey = await pubkeyRouter.getPubkey(pkpTokenId);
      console.log(`Got public key: ${publicKey}`);

      return {
        tokenId: pkpTokenId.toString(),
        ethAddress: params.pkpEthAddress,
        publicKey,
      };
    }

    /**
     * Checks if the session signer is a delegatee for the PKP.
     * @param {any} pkpToolRegistryContract - The PKP Tool Registry contract instance.
     */
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

    /**
     * Validates the swap inputs against the policy defined in the PKP Tool Registry.
     * @param {any} pkpToolRegistryContract - The PKP Tool Registry contract instance.
     * @param {any} amount - The amount of input token to swap.
     */
    async function validateInputsAgainstPolicy(
      pkpToolRegistryContract: any,
      amount: any
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

      // Decode policy - only maxAmount and allowedTokens
      console.log(`Decoding policy...`);
      const decodedPolicy = ethers.utils.defaultAbiCoder.decode(
        ['tuple(uint256 maxAmount, address[] allowedTokens)'],
        policyData
      )[0];

      // Validate amount
      if (amount.gt(decodedPolicy.maxAmount)) {
        throw new Error(
          `Amount exceeds policy limit. Max allowed: ${ethers.utils.formatEther(
            decodedPolicy.maxAmount
          )} ETH`
        );
      }

      // Validate input token
      if (
        decodedPolicy.allowedTokens.length > 0 &&
        !decodedPolicy.allowedTokens
          .map((addr: string) => ethers.utils.getAddress(addr))
          .includes(ethers.utils.getAddress(params.tokenIn))
      ) {
        throw new Error(
          `Token ${
            params.tokenIn
          } not allowed. Allowed tokens: ${decodedPolicy.allowedTokens.join(
            ', '
          )}`
        );
      }

      // Validate output token
      if (
        decodedPolicy.allowedTokens.length > 0 &&
        !decodedPolicy.allowedTokens
          .map((addr: string) => ethers.utils.getAddress(addr))
          .includes(ethers.utils.getAddress(params.tokenOut))
      ) {
        throw new Error(
          `Token ${
            params.tokenOut
          } not allowed. Allowed tokens: ${decodedPolicy.allowedTokens.join(
            ', '
          )}`
        );
      }

      console.log(`Inputs validated against policy`);
    }

    /**
     * Fetches token information (decimals, balance, etc.) for the input and output tokens.
     * @param {JsonRpcProvider} provider - The JSON-RPC provider instance.
     * @returns {Promise<{ tokenIn: { decimals: number, balance: any, amount: any, contract: any }, tokenOut: { decimals: number, balance: any, contract: any } }>} Token information.
     */
    async function getTokenInfo(provider: JsonRpcProvider) {
      console.log('Gathering token info...');
      ethers.utils.getAddress(params.tokenIn);
      ethers.utils.getAddress(params.tokenOut);

      // Check if the token contracts exist
      const codeIn = await provider.getCode(params.tokenIn);
      if (codeIn === '0x') {
        throw new Error(`No contract found at ${params.tokenIn}`);
      }
      const codeOut = await provider.getCode(params.tokenOut);
      if (codeOut === '0x') {
        throw new Error(`No contract found at ${params.tokenOut}`);
      }

      const tokenInterface = new ethers.utils.Interface([
        'function decimals() view returns (uint8)',
        'function balanceOf(address) view returns (uint256)',
        'function approve(address,uint256) external returns (bool)',
      ]);
      const tokenInContract = new ethers.Contract(
        params.tokenIn,
        tokenInterface,
        provider
      );
      const tokenOutContract = new ethers.Contract(
        params.tokenOut,
        tokenInterface,
        provider
      );

      // Parallel calls to fetch token details
      const [decimalsIn, decimalsOut] = await Promise.all([
        tokenInContract.decimals(),
        tokenOutContract.decimals(),
      ]);
      console.log('Token decimals:', decimalsIn, decimalsOut);

      const [balanceIn, balanceOut] = await Promise.all([
        tokenInContract.balanceOf(pkp.ethAddress),
        tokenOutContract.balanceOf(pkp.ethAddress),
      ]);
      console.log(
        'Token balances (in/out):',
        balanceIn.toString(),
        balanceOut.toString()
      );

      const amountIn = ethers.utils.parseUnits(params.amountIn, decimalsIn);
      if (amountIn.gt(balanceIn)) {
        throw new Error('Insufficient tokenIn balance');
      }
      return {
        tokenIn: {
          decimals: decimalsIn,
          balance: balanceIn,
          amount: amountIn,
          contract: tokenInContract,
        },
        tokenOut: {
          decimals: decimalsOut,
          balance: balanceOut,
          contract: tokenOutContract,
        },
      };
    }

    /**
     * Fetches the best quote for the swap from Uniswap V3.
     * @param {JsonRpcProvider} provider - The JSON-RPC provider instance.
     * @param {any} amount - The amount of input token to swap.
     * @param {number} decimalsOut - The number of decimals for the output token.
     * @returns {Promise<{ bestQuote: any, bestFee: number, amountOutMin: any }>} The best quote and fee tier.
     */
    async function getBestQuote(
      provider: JsonRpcProvider,
      amount: any,
      decimalsOut: number
    ) {
      console.log('Getting best quote for swap...');
      const quoterInterface = new ethers.utils.Interface([
        'function quoteExactInputSingle((address tokenIn, address tokenOut, uint256 amountIn, uint24 fee, uint160 sqrtPriceLimitX96)) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)',
      ]);

      const FEE_TIERS = [3000, 500]; // Supported fee tiers for Uniswap V3
      let bestQuote = null;
      let bestFee = null;

      for (const fee of FEE_TIERS) {
        try {
          const quoteParams = {
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: amount,
            fee: fee,
            sqrtPriceLimitX96: 0,
          };

          console.log(`Trying fee tier ${fee / 10000}%...`);
          const quote = await provider.call({
            to: UNISWAP_V3_QUOTER,
            data: quoterInterface.encodeFunctionData('quoteExactInputSingle', [
              quoteParams,
            ]),
          });

          const [amountOut] = quoterInterface.decodeFunctionResult(
            'quoteExactInputSingle',
            quote
          );
          const currentQuote = ethers.BigNumber.from(amountOut);

          if (!bestQuote || currentQuote.gt(bestQuote)) {
            bestQuote = currentQuote;
            bestFee = fee;
            console.log(
              `New best quote found with fee tier ${
                fee / 10000
              }%: ${ethers.utils.formatUnits(currentQuote, decimalsOut)}`
            );
          }
        } catch (error) {
          if ((error as { reason?: string }).reason === 'Unexpected error') {
            console.log(`No pool found for fee tier ${fee / 10000}%`);
          } else {
            console.error(
              'Debug: Quoter call failed for fee tier:',
              fee,
              error
            );
          }
          continue;
        }
      }

      if (!bestQuote || !bestFee) {
        throw new Error(
          'Failed to get quote from Uniswap V3. No valid pool found for this token pair.'
        );
      }

      // Calculate minimum output with 0.5% slippage tolerance
      const slippageTolerance = 0.005;
      const amountOutMin = bestQuote
        .mul(1000 - slippageTolerance * 1000)
        .div(1000);
      console.log(
        'Minimum output:',
        ethers.utils.formatUnits(amountOutMin, decimalsOut)
      );

      return { bestQuote, bestFee, amountOutMin };
    }

    /**
     * Fetches gas data (max fee, priority fee, nonce) for transactions.
     * @param {JsonRpcProvider} provider - The JSON-RPC provider instance.
     * @returns {Promise<{ maxFeePerGas: string, maxPriorityFeePerGas: string, nonce: number }>} Gas data.
     */
    async function getGasData(provider: JsonRpcProvider) {
      console.log(`Getting gas data...`);

      const gasData = await Lit.Actions.runOnce(
        { waitForResponse: true, name: 'gasPriceGetter' },
        async () => {
          const baseFeeHistory = await provider.send('eth_feeHistory', [
            '0x1',
            'latest',
            [],
          ]);
          const baseFee = ethers.BigNumber.from(
            baseFeeHistory.baseFeePerGas[0]
          );
          const nonce = await provider.getTransactionCount(pkp.ethAddress);

          const priorityFee = baseFee.div(4);
          const maxFee = baseFee.mul(2);

          return JSON.stringify({
            maxFeePerGas: maxFee.toHexString(),
            maxPriorityFeePerGas: priorityFee.toHexString(),
            nonce,
          });
        }
      );

      console.log(`Gas data: ${gasData}`);

      return JSON.parse(gasData);
    }

    /**
     * Estimates the gas limit for a transaction (approval or swap).
     * @param {JsonRpcProvider} provider - The JSON-RPC provider instance.
     * @param {any} tokenInContract - The input token contract instance.
     * @param {any} amount - The amount of input token to swap.
     * @param {boolean} isApproval - Whether the transaction is an approval or swap.
     * @param {Object} [swapParams] - Swap parameters (fee, amountOutMin) if applicable.
     * @returns {Promise<any>} The estimated gas limit.
     */
    async function estimateGasLimit(
      provider: JsonRpcProvider,
      tokenInContract: any,
      amount: any,
      isApproval: boolean,
      swapParams?: {
        fee: number;
        amountOutMin: any;
      }
    ) {
      console.log(`Estimating gas limit...`);

      try {
        let estimatedGas;
        if (isApproval) {
          estimatedGas = await tokenInContract.estimateGas.approve(
            UNISWAP_V3_ROUTER,
            amount,
            { from: pkp.ethAddress }
          );
        } else if (swapParams) {
          const routerInterface = new ethers.utils.Interface([
            'function exactInputSingle((address,address,uint24,address,uint256,uint256,uint160)) external payable returns (uint256)',
          ]);

          const routerContract = new ethers.Contract(
            UNISWAP_V3_ROUTER,
            routerInterface,
            provider
          );

          estimatedGas = await routerContract.estimateGas.exactInputSingle(
            [
              params.tokenIn,
              params.tokenOut,
              swapParams.fee,
              pkp.ethAddress,
              amount,
              swapParams.amountOutMin,
              0,
            ],
            { from: pkp.ethAddress }
          );
        } else {
          throw
