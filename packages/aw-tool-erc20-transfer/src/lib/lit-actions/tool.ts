import { fetchToolPolicyFromRegistry } from './utils/fetch-tool-policy-from-registry';
import { getTokenInfo } from './utils/erc20/get-erc20-info';
import { getPkpInfo } from './utils/get-pkp-info';
import { getPkpToolRegistryContract } from './utils/get-pkp-tool-registry-contract';
import { NETWORK_CONFIG } from './utils/network-config';
import { getGasData } from './utils/erc20/get-gas-data';
import { estimateGasLimit } from './utils/erc20/estimate-gas-limit';
import { createAndSignTransaction } from './utils/erc20/create-and-sign-tx';
import { broadcastTransaction } from './utils/erc20/broadcast-tx';

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

  // Injected by build script
  const LIT_NETWORK: string;
  const PKP_TOOL_REGISTRY_ADDRESS: string;

  // Required Inputs
  const params: {
    pkpEthAddress: string;
    rpcUrl: string;
    chainId: string;
    tokenIn: string;
    recipientAddress: string;
    amountIn: string;
  };
}

export default async () => {
  try {
    console.log(`Using Lit Network: ${LIT_NETWORK}`);
    console.log(
      `Using PKP Tool Registry Address: ${PKP_TOOL_REGISTRY_ADDRESS}`
    );
    console.log(
      `Using Pubkey Router Address: ${
        NETWORK_CONFIG[LIT_NETWORK as keyof typeof NETWORK_CONFIG]
          .pubkeyRouterAddress
      }`
    );

    const delegateeAddress = ethers.utils.getAddress(LitAuth.authSigAddress);
    const toolIpfsCid = LitAuth.actionIpfsIds[0];
    const provider = new ethers.providers.JsonRpcProvider(params.rpcUrl);
    const pkpToolRegistryContract = await getPkpToolRegistryContract(
      PKP_TOOL_REGISTRY_ADDRESS
    );
    const pkp = await getPkpInfo(params.pkpEthAddress);
    const tokenInfo = await getTokenInfo(
      provider,
      params.tokenIn,
      pkp.ethAddress
    );

    const toolPolicyIpfsCid = await fetchToolPolicyFromRegistry(
      pkpToolRegistryContract,
      pkp.tokenId,
      delegateeAddress,
      toolIpfsCid
    );
    await Lit.Actions.call({
      ipfsId: toolPolicyIpfsCid,
      params: {
        pkpToolRegistryContract,
        pkpTokenId: pkp.tokenId,
        delegateeAddress,
        toolParameters: {
          tokenInfo,
          rpcUrl: params.rpcUrl,
          chainId: params.chainId,
          tokenIn: params.tokenIn,
          recipientAddress: params.recipientAddress,
          amountIn: params.amountIn,
        },
      },
    });

    const gasData = await getGasData(provider, pkp.ethAddress);
    const gasLimit = await estimateGasLimit(
      provider,
      tokenInfo.amount,
      pkp.ethAddress
    );
    const signedTx = await createAndSignTransaction(
      params.tokenIn,
      params.recipientAddress,
      tokenInfo.amount,
      gasLimit,
      gasData,
      params.chainId,
      pkp.publicKey
    );

    const result = await broadcastTransaction(provider, signedTx);
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
