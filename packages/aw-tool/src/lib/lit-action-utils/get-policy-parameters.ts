/**
 * Retrieves specific policy parameters for a tool and delegatee combination.
 * This function fetches parameter values that have been set in the tool's policy
 * for a particular delegatee.
 * 
 * @param pkpToolRegistryContract - The PKP Tool Registry contract instance.
 * @param pkpTokenId - The token ID of the PKP.
 * @param toolIpfsCid - The IPFS CID of the tool.
 * @param delegateeAddress - The Ethereum address of the delegatee.
 * @param parameterNames - Array of parameter names to retrieve from the policy.
 * @returns A promise that resolves to the requested policy parameter values.
 */
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
