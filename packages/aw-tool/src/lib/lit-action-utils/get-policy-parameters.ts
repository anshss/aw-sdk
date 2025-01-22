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
  const [policyParameter] =
    await pkpToolRegistryContract.getToolPolicyParameters(
      pkpTokenId,
      toolIpfsCid,
      delegateeAddress,
      parameterNames
    );
  console.log(`Policy parameter: ${policyParameter}`);
  return policyParameter;
};
