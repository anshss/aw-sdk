/**
 * Creates an instance of the PKP Tool Registry contract.
 * This function initializes a contract instance with the core functions needed for
 * delegatee verification and policy management within Lit Actions.
 * 
 * @param pkpToolRegistryAddress - The Ethereum address of the PKP Tool Registry contract.
 * @returns A promise that resolves to an ethers Contract instance connected to the PKP Tool Registry.
 */
export const getPkpToolRegistryContract = async (
  pkpToolRegistryAddress: string
) => {
  // Create contract instance
  const PKP_TOOL_REGISTRY_ABI = [
    'function isPkpDelegatee(uint256 pkpTokenId, address delegatee) external view returns (bool)',
    'function getToolPoliciesForDelegatees(uint256 pkpTokenId, string[] calldata toolIpfsCids, address[] calldata delegatees) external view returns (ToolPolicy[] memory toolPolicies)',
    'function getToolPolicyParameters(uint256 pkpTokenId, string calldata toolIpfsCid, address delegatee, string[] calldata parameterNames) external view returns (Parameter[] memory parameters)',
  ];
  return new ethers.Contract(
    pkpToolRegistryAddress,
    PKP_TOOL_REGISTRY_ABI,
    new ethers.providers.JsonRpcProvider(
      await Lit.Actions.getRpcUrl({
        chain: 'yellowstone',
      })
    )
  );
};
