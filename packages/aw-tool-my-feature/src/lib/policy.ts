import { PolicyConfig } from '@lit-protocol/aw-tool';

export interface MyFeaturePolicyConfig extends PolicyConfig {
  // Add your tool's policy configuration interface here
}

export function validatePolicy(policy: MyFeaturePolicyConfig): boolean {
  // Add your policy validation logic here
  return true;
}