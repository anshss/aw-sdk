# AW Contracts

This repository contains Solidity smart contracts for managing ERC20 tokens and PKP (Programmable Key Pair) NFT tool policies. The core contracts are located in the `./src/` folder.

## Contracts

### 1. `DevERC20`

A simple ERC20 token contract designed for testing and development purposes.

#### Features:
- **Minting**: Allows anyone to mint tokens for testing via the `mint` function.
- **ERC20 Compliance**: Inherits from OpenZeppelin's ERC20 implementation, ensuring standard ERC20 functionality.

#### Key Functions:
- `mint(address to, uint256 amount)`: Mints `amount` tokens and assigns them to the `to` address.

#### Usage:
This contract is ideal for testing scenarios where an ERC20 token is required. It should not be used in production due to its unrestricted minting capability.

---

### 2. `PKPToolPolicyRegistry`

Manages tool policies and delegatees for PKP NFTs. This contract allows the owner of a PKP NFT to set policies for specific tools and manage delegatees who can execute tools on their behalf.

#### Features:
- **Policy Management**: 
  - Set, update, or remove policies for tools identified by IPFS CIDs.
- **Delegatee Management**:
  - Add or remove delegatees who can execute tools on behalf of the PKP owner.
- **Custom Errors**: Efficient error handling with custom errors.
- **Events**: Emits events for policy changes and delegatee updates.

#### Key Functions:
- `setPolicy(uint256 pkpId, bytes32 toolCid, bytes memory policy)`: Sets or updates a policy for a specific tool identified by `toolCid` for the PKP NFT with ID `pkpId`.
- `removePolicy(uint256 pkpId, bytes32 toolCid)`: Removes the policy for a specific tool identified by `toolCid` for the PKP NFT with ID `pkpId`.
- `addDelegatee(uint256 pkpId, address delegatee)`: Adds a delegatee who can execute tools on behalf of the PKP owner.
- `removeDelegatee(uint256 pkpId, address delegatee)`: Removes a delegatee from the PKP NFT with ID `pkpId`.

#### Events:
- `PolicyUpdated(uint256 indexed pkpId, bytes32 indexed toolCid, bytes policy)`: Emitted when a policy is set or updated.
- `PolicyRemoved(uint256 indexed pkpId, bytes32 indexed toolCid)`: Emitted when a policy is removed.
- `DelegateeAdded(uint256 indexed pkpId, address delegatee)`: Emitted when a delegatee is added.
- `DelegateeRemoved(uint256 indexed pkpId, address delegatee)`: Emitted when a delegatee is removed.

#### Usage:
This contract is designed for managing permissions and policies for PKP NFTs, enabling flexible and programmable access control for tools and delegatees.
