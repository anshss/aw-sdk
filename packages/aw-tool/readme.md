# AW-Tool Documentation

The `aw-tool` folder contains utilities for building Function-as-a-Service (FaaS) tools, particularly for interacting with the Lit Protocol and Ethereum blockchain.

---

## Supported Lit Networks

Defines the Lit networks supported by the tool:

- **DatilDev**: Development environment.
- **DatilTest**: Testing environment.
- **Datil**: Production environment.

---

## Network Configurations

Maps network names to their configurations. Each configuration includes:

- `litNetwork`: Lit network identifier.
- `ipfsCid`: IPFS CID for the network.

---

## Ethereum Address Validation

Validates Ethereum addresses using a Zod schema. Ensures the address follows the format `0x` followed by 40 hexadecimal characters.

---

## AW Tool Interface

A generic interface for FaaS tools. It includes:

- **Basic Info**: Name, description, and IPFS CID.
- **Parameters**: Type, schema, descriptions, and validation.
- **Policy**: Type, version, schema, and encode/decode functions.

---

## Example Usage

Define and use an `AwTool`:

```typescript
const myTool: AwTool<{ amount: number }, { type: 'basic', threshold: number }> = {
  name: 'MyTool',
  description: 'A tool for transferring ERC20 tokens.',
  ipfsCid: 'QmExampleCID',

  parameters: {
    type: { amount: 0 },
    schema: z.object({ amount: z.number().min(0) }),
    descriptions: { amount: 'The amount of tokens to transfer.' },
    validate: (params) => {
      const result = myTool.parameters.schema.safeParse(params);
      if (!result.success) {
        return result.error.errors.map(err => ({
          param: err.path.join('.'),
          error: err.message,
        }));
      }
      return true;
    },
  },

  policy: {
    type: { type: 'basic', threshold: 0 },
    version: '1.0',
    schema: z.object({ type: z.literal('basic'), threshold: z.number().min(0) }),
    encode: (policy) => JSON.stringify(policy),
    decode: (encodedPolicy) => JSON.parse(encodedPolicy),
  },
};
```
