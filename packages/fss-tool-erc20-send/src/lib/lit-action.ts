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
    chainId: number;
    tokenIn: string;
    recipientAddress: string;
    amountIn: string;
  };
}

export default async () => {
  try {
    // Check if the session signer is a delegatee
    async function checkLitAuthAddressIsDelegatee(
      pkpToolRegistryContract: any
    ) {
      // Check if the session signer is a delegatee
      const sessionSigner = ethers.utils.getAddress(LitAuth.address);
      const isDelegatee = await pkpToolRegistryContract.isDelegateeOf(
        pkp.tokenId,
        sessionSigner
      );

      if (!isDelegatee) {
        throw new Error(
          `Session signer ${sessionSigner} is not a delegatee for PKP ${pkp.tokenId}`
        );
      }
    }

    async function validateInputsAgainstPolicy(
      pkpToolRegistryContract: any,
      amount: any
    ) {
      // Get policy for this tool
      const TOOL_IPFS_CID = LitAuth.actionIpfsIds[0];
      const [policyData] = await pkpToolRegistryContract.getActionPolicy(
        pkp.tokenId,
        TOOL_IPFS_CID
      );

      // Decode policy
      const decodedPolicy = ethers.utils.defaultAbiCoder.decode(
        [
          'tuple(uint256 maxAmount, address[] allowedTokens, address[] allowedRecipients)',
        ],
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

      // Validate token
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

      // Validate recipient
      if (
        decodedPolicy.allowedRecipients.length > 0 &&
        !decodedPolicy.allowedRecipients
          .map((addr: string) => ethers.utils.getAddress(addr))
          .includes(ethers.utils.getAddress(params.recipientAddress))
      ) {
        throw new Error(
          `Recipient ${
            params.recipientAddress
          } not allowed. Allowed recipients: ${decodedPolicy.allowedRecipients.join(
            ', '
          )}`
        );
      }
    }

    async function getTokenInfo(provider: any) {
      console.log('Getting token info for:', params.tokenIn);

      // Validate token address
      try {
        ethers.utils.getAddress(params.tokenIn);
      } catch (error) {
        throw new Error(`Invalid token address: ${params.tokenIn}`);
      }

      // Check if contract exists
      const code = await provider.getCode(params.tokenIn);
      if (code === '0x') {
        throw new Error(`No contract found at address: ${params.tokenIn}`);
      }

      const tokenInterface = new ethers.utils.Interface([
        'function decimals() view returns (uint8)',
        'function balanceOf(address account) view returns (uint256)',
        'function transfer(address to, uint256 amount) external returns (bool)',
      ]);

      console.log('Creating token contract instance...');
      const tokenContract = new ethers.Contract(
        params.tokenIn,
        tokenInterface,
        provider
      );

      console.log('Fetching token decimals and balance...');
      try {
        const decimals = await tokenContract.decimals();
        console.log('Token decimals:', decimals);

        const balance = await tokenContract.balanceOf(pkp.ethAddress);
        console.log('Token balance:', balance.toString());

        const amount = ethers.utils.parseUnits(params.amountIn, decimals);
        console.log('Amount to send:', amount.toString());

        if (amount.gt(balance)) {
          throw new Error(
            `Insufficient balance. PKP balance: ${ethers.utils.formatUnits(
              balance,
              decimals
            )}. Required: ${ethers.utils.formatUnits(amount, decimals)}`
          );
        }

        return { decimals, balance, amount };
      } catch (error) {
        console.error('Error getting token info:', error);
        throw new Error(
          `Failed to interact with token contract at ${params.tokenIn}. Make sure this is a valid ERC20 token contract.`
        );
      }
    }

    async function getGasData() {
      const gasData = await Lit.Actions.runOnce(
        { waitForResponse: true, name: 'gasPriceGetter' },
        async () => {
          const provider = new ethers.providers.JsonRpcProvider(params.rpcUrl);
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

      return JSON.parse(gasData);
    }

    async function estimateGasLimit(provider: any, amount: any) {
      const tokenInterface = new ethers.utils.Interface([
        'function transfer(address to, uint256 amount) external returns (bool)',
      ]);

      const tokenContract = new ethers.Contract(
        params.tokenIn,
        tokenInterface,
        provider
      );

      try {
        const estimatedGas = await tokenContract.estimateGas.transfer(
          params.recipientAddress,
          amount,
          { from: pkp.ethAddress }
        );
        console.log('Estimated gas limit:', estimatedGas.toString());
        return estimatedGas.mul(120).div(100);
      } catch (error) {
        console.error(
          'Could not estimate gas. Using fallback gas limit of 100000.',
          error
        );
        return ethers.BigNumber.from('100000');
      }
    }

    async function createAndSignTransaction(
      gasLimit: any,
      amount: any,
      gasData: any
    ) {
      const tokenInterface = new ethers.utils.Interface([
        'function transfer(address to, uint256 amount) external returns (bool)',
      ]);

      const transferTx = {
        to: params.tokenIn,
        data: tokenInterface.encodeFunctionData('transfer', [
          params.recipientAddress,
          amount,
        ]),
        value: '0x0',
        gasLimit: gasLimit.toHexString(),
        maxFeePerGas: gasData.maxFeePerGas,
        maxPriorityFeePerGas: gasData.maxPriorityFeePerGas,
        nonce: gasData.nonce,
        chainId: params.chainId,
        type: 2,
      };

      console.log('Signing transfer...');
      const transferSig = await Lit.Actions.signAndCombineEcdsa({
        toSign: ethers.utils.arrayify(
          ethers.utils.keccak256(ethers.utils.serializeTransaction(transferTx))
        ),
        publicKey: pkp.publicKey,
        sigName: 'erc20TransferSig',
      });

      return ethers.utils.serializeTransaction(
        transferTx,
        ethers.utils.joinSignature({
          r: '0x' + JSON.parse(transferSig).r.substring(2),
          s: '0x' + JSON.parse(transferSig).s,
          v: JSON.parse(transferSig).v,
        })
      );
    }

    async function broadcastTransaction(signedTx: string) {
      console.log('Broadcasting transfer...');
      return await Lit.Actions.runOnce(
        { waitForResponse: true, name: 'txnSender' },
        async () => {
          try {
            const provider = new ethers.providers.JsonRpcProvider(
              params.rpcUrl
            );
            const tx = await provider.sendTransaction(signedTx);
            console.log('Transaction sent:', tx.hash);

            const receipt = await tx.wait(1);
            console.log('Transaction mined:', receipt.transactionHash);

            return receipt.transactionHash;
          } catch (err: any) {
            // Log the full error object for debugging
            console.error('Full error object:', JSON.stringify(err, null, 2));

            // Extract detailed error information
            const errorDetails = {
              message: err.message,
              code: err.code,
              reason: err.reason,
              error: err.error,
              ...(err.transaction && { transaction: err.transaction }),
              ...(err.receipt && { receipt: err.receipt }),
            };

            console.error(
              'Error details:',
              JSON.stringify(errorDetails, null, 2)
            );

            // Return stringified error response
            return JSON.stringify({
              error: true,
              message: err.reason || err.message || 'Transaction failed',
              details: errorDetails,
            });
          }
        }
      );
    }

    // Main Execution
    const provider = new ethers.providers.JsonRpcProvider(params.rpcUrl);
    const tokenInfo = await getTokenInfo(provider);

    // Create contract instance
    const PKP_TOOL_REGISTRY_ABI = [
      'function isDelegateeOf(uint256 pkpTokenId, address delegatee) external view returns (bool)',
      'function getActionPolicy(address pkp, string calldata ipfsCid) external view returns (bytes memory policy, string memory version)',
    ];
    const PKP_TOOL_REGISTRY = '0xD78e1C1183A29794A092dDA7dB526A91FdE36020';
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
      pkpToolRegistryContract,
      tokenInfo.amount
    );

    const gasData = await getGasData();
    const gasLimit = await estimateGasLimit(provider, tokenInfo.amount);
    const signedTx = await createAndSignTransaction(
      gasLimit,
      tokenInfo.amount,
      gasData
    );
    const result = await broadcastTransaction(signedTx);

    console.log('Result:', result);

    // Try to parse the result
    let parsedResult;
    try {
      parsedResult = JSON.parse(result);
    } catch {
      // If it's not JSON, assume it's a transaction hash
      parsedResult = result;
    }

    // Check if result is an error object
    if (typeof parsedResult === 'object' && parsedResult.error) {
      throw new Error(parsedResult.message);
    }

    // At this point, result should be a transaction hash
    if (!parsedResult) {
      throw new Error('Transaction failed: No transaction hash returned');
    }

    if (!ethers.utils.isHexString(parsedResult)) {
      throw new Error(
        `Transaction failed: Invalid transaction hash format. Received: ${JSON.stringify(
          parsedResult
        )}`
      );
    }

    Lit.Actions.setResponse({
      response: JSON.stringify({
        status: 'success',
        transferHash: parsedResult,
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

    // Construct a detailed error message
    const errorMessage = err.message || String(err);

    Lit.Actions.setResponse({
      response: JSON.stringify({
        status: 'error',
        error: errorMessage,
        details: errorDetails,
      }),
    });
  }
};
