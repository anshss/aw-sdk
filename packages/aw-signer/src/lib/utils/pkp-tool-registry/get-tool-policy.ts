import type { ethers } from 'ethers';

/**
 * Get the policy for a specific tool and delegatee
 * @param ipfsCid IPFS CID of the tool
 * @param delegatee Address of the delegatee
 * @returns The policy IPFS CID and enabled status for the tool
 */
export const getToolPolicy = async (
  toolPolicyRegistryContract: ethers.Contract,
  pkpTokenId: string,
  ipfsCid: string,
  delegatee: string
): Promise<{ policyIpfsCid: string; enabled: boolean }> => {
  const [policyIpfsCid, enabled] =
    await toolPolicyRegistryContract.getToolPolicyForDelegatee(
      pkpTokenId,
      ipfsCid,
      delegatee
    );

  return {
    policyIpfsCid: policyIpfsCid === '' ? null : policyIpfsCid,
    enabled,
  };
};
