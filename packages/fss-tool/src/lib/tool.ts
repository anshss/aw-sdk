import { z } from 'zod';

export const BaseEthereumAddressSchema = z
  .string()
  .regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum address format');

export type EthereumAddress = z.infer<typeof BaseEthereumAddressSchema>;

export interface FssTool<
  TParams extends Record<string, any> = Record<string, any>,
  TPolicy extends { type: string } = { type: string }
> {
  // Basic tool information
  name: string;
  description: string;
  ipfsCid: string;

  // Parameter handling
  parameters: {
    type: TParams;
    schema: z.ZodType<TParams>;
    descriptions: Readonly<Record<keyof TParams, string>>;
    validate: (
      params: unknown
    ) => true | Array<{ param: string; error: string }>;
  };

  // Policy handling
  policy: {
    type: TPolicy;
    schema: z.ZodType<TPolicy>;
    encode: (policy: TPolicy) => string;
    decode: (encodedPolicy: string) => TPolicy;
  };
}
