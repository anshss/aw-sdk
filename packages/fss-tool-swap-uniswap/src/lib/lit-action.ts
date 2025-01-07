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
      formatUnits: any;
      formatEther: any;
      arrayify: any;
      keccak256: any;
      serializeTransaction: any;
      joinSignature: any;
      isHexString: any;
      getAddress: any;
      defaultAbiCoder: any;
    };
    BigNumber: any;
    Contract: any;
  };

  // Required Inputs
  const pkp: {
    tokenId: string;
    ethAddress: string;
    publicKey: string;
  };
  const params: {
    rpcUrl: string;
    chainId: string;
    tokenIn: string;
    tokenOut: string;
    amountIn: string;
  };
}

type JsonRpcProvider = ReturnType<typeof ethers.providers.JsonRpcProvider>;

export default async () => {
  try {
    let UNISWAP_V3_QUOTER: string;
    let UNISWAP_V3_ROUTER: string;
    switch (params.chainId) {
      case '8453':
        UNISWAP_V3_QUOTER = '0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a';
        UNISWAP_V3_ROUTER = '0x2626664c2603336E57B271c5C0b26F421741e481';
        break;
      case '1':
      case '42161':
        UNISWAP_V3_QUOTER = '0x61fFE014bA17989E743c5F6cB21bF9697530B21e';
        UNISWAP_V3_ROUTER = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45';
        break;
      default:
        throw new Error(`Unsupported chain ID: ${params.chainId}`);
    }

    // Check if the session signer is a delegatee
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

    async function getTokenInfo(provider: JsonRpcProvider) {
      console.log('Gathering token info...');
      ethers.utils.getAddress(params.tokenIn);
      ethers.utils.getAddress(params.tokenOut);

      // Check code
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

      // Parallel calls
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

    async function getBestQuote(
      provider: JsonRpcProvider,
      amount: any,
      decimalsOut: number
    ) {
      console.log('Getting best quote for swap...');
      const quoterInterface = new ethers.utils.Interface([
        'function quoteExactInputSingle((address tokenIn, address tokenOut, uint256 amountIn, uint24 fee, uint160 sqrtPriceLimitX96)) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)',
      ]);

      const FEE_TIERS = [3000, 500];
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
          throw new Error('Missing swap parameters for gas estimation');
        }

        // Add 20% buffer
        const gasLimit = estimatedGas.mul(120).div(100);
        console.log(`Estimated gas limit: ${gasLimit.toString()}`);
        return gasLimit;
      } catch (error) {
        console.error('Error estimating gas:', error);
        // Use fallback gas limits
        const fallbackGas = isApproval ? '300000' : '500000';
        console.log(`Using fallback gas limit: ${fallbackGas}`);
        return ethers.BigNumber.from(fallbackGas);
      }
    }

    async function signTx(tx: any, sigName: string) {
      console.log(`Signing TX: ${sigName}`);
      const pkForLit = pkp.publicKey.startsWith('0x')
        ? pkp.publicKey.slice(2)
        : pkp.publicKey;

      const sig = await Lit.Actions.signAndCombineEcdsa({
        toSign: ethers.utils.arrayify(
          ethers.utils.keccak256(ethers.utils.serializeTransaction(tx))
        ),
        publicKey: pkForLit,
        sigName,
      });

      return ethers.utils.serializeTransaction(
        tx,
        ethers.utils.joinSignature({
          r: '0x' + JSON.parse(sig).r.substring(2),
          s: '0x' + JSON.parse(sig).s,
          v: JSON.parse(sig).v,
        })
      );
    }

    async function createTransaction(
      gasLimit: any,
      amount: any,
      gasData: any,
      isApproval: boolean,
      swapParams?: {
        fee: number;
        amountOutMin: any;
      }
    ) {
      console.log(`Creating transaction...`);

      let txData;
      if (isApproval) {
        const tokenInterface = new ethers.utils.Interface([
          'function approve(address spender, uint256 amount) external returns (bool)',
        ]);
        txData = tokenInterface.encodeFunctionData('approve', [
          UNISWAP_V3_ROUTER,
          amount,
        ]);
      } else if (swapParams) {
        const routerInterface = new ethers.utils.Interface([
          'function exactInputSingle((address,address,uint24,address,uint256,uint256,uint160)) external payable returns (uint256)',
        ]);
        txData = routerInterface.encodeFunctionData('exactInputSingle', [
          [
            params.tokenIn,
            params.tokenOut,
            swapParams.fee,
            pkp.ethAddress,
            amount,
            swapParams.amountOutMin,
            0,
          ],
        ]);
      } else {
        throw new Error('Missing swap parameters for transaction creation');
      }

      return {
        to: isApproval ? params.tokenIn : UNISWAP_V3_ROUTER,
        data: txData,
        value: '0x0',
        gasLimit: gasLimit.toHexString(),
        maxFeePerGas: gasData.maxFeePerGas,
        maxPriorityFeePerGas: gasData.maxPriorityFeePerGas,
        nonce: gasData.nonce,
        chainId: params.chainId,
        type: 2,
      };
    }

    async function broadcastTransaction(signedTx: string) {
      console.log('Broadcasting transaction...');
      const txHash = await Lit.Actions.runOnce(
        { waitForResponse: true, name: 'txnSender' },
        async () => {
          try {
            const provider = new ethers.providers.JsonRpcProvider(
              params.rpcUrl
            );
            const receipt = await provider.sendTransaction(signedTx);
            console.log('Transaction sent:', receipt.hash);
            return receipt.hash;
          } catch (error) {
            console.error('Error broadcasting transaction:', error);
            throw error;
          }
        }
      );

      if (!ethers.utils.isHexString(txHash)) {
        throw new Error(`Invalid transaction hash: ${txHash}`);
      }

      return txHash;
    }

    // Main Execution
    console.log('Starting Uniswap swap execution...');
    const provider = new ethers.providers.JsonRpcProvider(params.rpcUrl);

    // Set up PKP Tool Registry
    const PKP_TOOL_REGISTRY_ABI = [
      'function isDelegateeOf(uint256,address) external view returns (bool)',
      'function getToolPolicy(uint256,string) external view returns (bytes memory, string memory)',
    ];
    const PKP_TOOL_REGISTRY_ADDR = '0xb8000069FeD07794c23Fc1622F02fe54788Dae3F';
    const pkpToolRegistry = new ethers.Contract(
      PKP_TOOL_REGISTRY_ADDR,
      PKP_TOOL_REGISTRY_ABI,
      new ethers.providers.JsonRpcProvider(
        await Lit.Actions.getRpcUrl({ chain: 'yellowstone' })
      )
    );

    // Check if the session signer is a delegatee
    await checkLitAuthAddressIsDelegatee(pkpToolRegistry);

    // Get token info and validate balances
    const tokenInfo = await getTokenInfo(provider);

    // Validate inputs against policy
    await validateInputsAgainstPolicy(
      pkpToolRegistry,
      tokenInfo.tokenIn.amount
    );

    // Get best quote and calculate minimum output
    const { bestFee, amountOutMin } = await getBestQuote(
      provider,
      tokenInfo.tokenIn.amount,
      tokenInfo.tokenOut.decimals
    );

    // Get gas data for transactions
    const gasData = await getGasData(provider);

    // Approval Transaction
    const approvalGasLimit = await estimateGasLimit(
      provider,
      tokenInfo.tokenIn.contract,
      tokenInfo.tokenIn.amount,
      true
    );

    const approvalTx = await createTransaction(
      approvalGasLimit,
      tokenInfo.tokenIn.amount,
      gasData,
      true
    );

    const signedApprovalTx = await signTx(approvalTx, 'erc20ApprovalSig');
    const approvalHash = await broadcastTransaction(signedApprovalTx);
    console.log('Approval transaction hash:', approvalHash);

    // Wait for approval confirmation
    console.log('Waiting for approval confirmation...');
    const approvalConfirmation = await provider.waitForTransaction(
      approvalHash,
      1
    );
    if (approvalConfirmation.status === 0) {
      throw new Error('Approval transaction failed');
    }

    // Swap Transaction
    const swapGasLimit = await estimateGasLimit(
      provider,
      tokenInfo.tokenIn.contract,
      tokenInfo.tokenIn.amount,
      false,
      { fee: bestFee, amountOutMin }
    );

    const swapTx = await createTransaction(
      swapGasLimit,
      tokenInfo.tokenIn.amount,
      { ...gasData, nonce: gasData.nonce + 1 },
      false,
      { fee: bestFee, amountOutMin }
    );

    const signedSwapTx = await signTx(swapTx, 'erc20SwapSig');
    const swapHash = await broadcastTransaction(signedSwapTx);
    console.log('Swap transaction hash:', swapHash);

    Lit.Actions.setResponse({
      response: JSON.stringify({
        status: 'success',
        approvalHash,
        swapHash,
      }),
    });
  } catch (err: any) {
    console.error('Error:', err);

    // Extract detailed error information
    const errorDetails = {
      message: err.message,
      code: err.code,
      reason: err.reason,
      error: err.error,
      ...(err.transaction && { transaction: err.transaction }),
      ...(err.receipt && { receipt: err.receipt }),
    };

    Lit.Actions.setResponse({
      response: JSON.stringify({
        status: 'error',
        error: err.message || String(err),
        details: errorDetails,
      }),
    });
  }
};
