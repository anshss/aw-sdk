/**
 * Fetches the policy for a specific tool and delegatee from the PKP Tool Registry.
 * This function retrieves the policy configuration that defines how a delegatee
 * can use a particular tool with a PKP.
 * 
 * @param pkpToolRegistryContract - The PKP Tool Registry contract instance.
 * @param pkpTokenId - The token ID of the PKP.
 * @param delegateeAddress - The Ethereum address of the delegatee.
 * @param toolIpfsCid - The IPFS CID of the tool whose policy should be fetched.
 * @returns A promise that resolves to the tool's policy configuration for the specified delegatee.
 */
export const fetchToolPolicyFromRegistry = async (
  pkpToolRegistryContract: any,
  pkpTokenId: string,
  delegateeAddress: string,
  toolIpfsCid: string
) => {
  console.log(
    `Fetching tool policy from PKP Tool Registry: ${pkpToolRegistryContract.address}...`,
    `PKP Token ID: ${pkpTokenId}`,
    `Delegatee Address: ${delegateeAddress}`,
    `Tool IPFS CID: ${toolIpfsCid}`
  );

  const toolPolicy = (
    await pkpToolRegistryContract.getToolPoliciesForDelegatees(
      pkpTokenId,
      [toolIpfsCid],
      [delegateeAddress]
    )
  )[0];

  console.log(`Tool Policy: ${toolPolicy}`);
  return toolPolicy;
};
