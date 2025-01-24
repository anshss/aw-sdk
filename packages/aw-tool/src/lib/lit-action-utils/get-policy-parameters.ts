export const getPolicyParameters = async (
  pkpToolRegistryContract: any,
  pkpTokenId: string,
  toolIpfsCid: string,
  delegateeAddress: string,
  parameterNames: string[]
) => {
  console.log(
    `Getting policy parameters ${parameterNames} for PKP ${pkpTokenId}...`
  );
  return pkpToolRegistryContract.getToolPolicyParameters(
    pkpTokenId,
    toolIpfsCid,
    delegateeAddress,
    parameterNames
  );
};
