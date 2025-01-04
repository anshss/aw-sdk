import { z } from 'zod';
import { BaseAgentToolPolicy } from '@lit-protocol/fss-tool-policy-base';

// Base interface for tool parameters
export interface BaseFSSTool<
  TParams extends Record<string, any> = Record<string, any>,
  TPolicy extends BaseAgentToolPolicy = BaseAgentToolPolicy,
  TMetadata extends Record<string, any> = Record<string, any>
> {
  // Basic tool information
  description: string;
  ipfsCid: string;

  // Parameter handling
  Parameters: {
    type: TParams;
    schema: z.ZodType<TParams>;
    descriptions: Record<keyof TParams, string>;
    validate: (params: unknown) => params is TParams;
  };

  // Tool metadata
  metadata: TMetadata;

  // Policy handling
  Policy: {
    type: TPolicy;
    schema: z.ZodType<TPolicy>;
    encode: (policy: TPolicy) => string;
    decode: (encodedPolicy: string, version: string) => TPolicy;
  };
}

// Type for tool registration info
export interface FSSToolInfo {
  name: string;
  description: string;
  ipfsCid: string;
  parameters: {
    name: string;
    description: string;
  }[];
}
