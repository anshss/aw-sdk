declare global {
  // Injected By Lit
  const Lit: any;
  const LitAuth: any;

  // Injected by build script
  const LIT_NETWORK: string;
  const PKP_TOOL_REGISTRY_ADDRESS: string;

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
      toUtf8Bytes: any;
    };
    BigNumber: any;
    Contract: any;
  };
}

export * from './check-lit-auth-address-is-delegatee';
export * from './fetch-tool-policy-from-registry';
export * from './get-pkp-info';
export * from './get-pkp-tool-registry-contract';
export * from './get-policy-parameters';
export * from './network-config';
