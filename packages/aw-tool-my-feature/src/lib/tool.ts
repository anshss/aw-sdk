import { Tool, ToolConfig } from '@lit-protocol/aw-tool';
import { MyFeaturePolicyConfig, validatePolicy } from './policy';

export class MyFeatureTool extends Tool {
  constructor(config: ToolConfig) {
    super(config);
  }

  // Add your tool's specific functionality here
}