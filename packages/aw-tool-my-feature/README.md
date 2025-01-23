# AW-Tool MyFeature Documentation

The `aw-tool-my-feature` package provides functionality for performing ECDSA signing operations using Lit Protocol's PKPs (Programmable Key Pairs). This tool enables secure signing of arbitrary messages or transactions while enforcing policy-based controls.

---

## Files Overview (in src/lib)

### 1. **`ipfs.ts`**
Handles IPFS CIDs for different environments (development, testing, production). Falls back to default CIDs if the build output is not found.

#### Key Features:
- **Default CIDs**: Predefined CIDs for `datil-dev`, `datil-test`, and `datil` environments
- **Dynamic CID Loading**: Attempts to load CIDs from `dist/ipfs.json` at runtime
- **Fallback Mechanism**: Uses default CIDs if the file is missing or unreadable

---

### 2. **`lit-action.ts`**
Contains the main logic for executing a Lit Action to perform ECDSA signing operations.

#### Key Features:
- **PKP Info Retrieval**: Fetches PKP details (token ID, Ethereum address, public key) from the PubkeyRouter contract
- **Delegatee Validation**: Verifies that the session signer is a valid delegatee for the PKP
- **Policy Enforcement**: Validates message prefixes against the allowed prefixes in the policy
- **Message Signing**: Signs messages using the PKP's public key via Lit Actions
- **Error Handling**: Comprehensive error handling and response formatting

---

### 3. **`policy.ts`**
Defines and validates the ECDSA signing policy schema using Zod.

#### Key Features:
- **Policy Schema**: Validates policy fields:
  - `type`: Must be 'SignEcdsa'
  - `version`: Policy version string
  - `allowedPrefixes`: Array of allowed message prefixes
- **Encoding/Decoding**: Converts policies to and from ABI-encoded strings using ethers
- **Type Safety**: Uses Zod for schema validation and TypeScript type inference

---

### 4. **`tool.ts`**
Configures the ECDSA signing tool for different Lit networks.

#### Key Features:
- **Parameter Schema**: Validates required parameters:
  - `pkpEthAddress`: The Ethereum address of the PKP
  - `message`: The message to be signed
- **Network Configuration**: Creates network-specific tools for each supported Lit network
- **Tool Definition**: Implements the `AwTool` interface with:
  - Name and description
  - Parameter validation and descriptions
  - Policy integration with `SignEcdsaPolicy`
