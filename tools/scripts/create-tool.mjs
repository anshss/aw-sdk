#!/usr/bin/env node

import { execSync } from 'child_process';
import { copyFileSync, mkdirSync, readdirSync, readFileSync, writeFileSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Get tool name from command line args
const toolName = process.argv[2];
if (!toolName) {
  console.error('Please provide a tool name: pnpm new-tool <tool-name>');
  process.exit(1);
}

const packageName = `aw-tool-${toolName}`;
const className = toolName
  .split('-')
  .map(part => part.charAt(0).toUpperCase() + part.slice(1))
  .join('');

const packagePath = join(__dirname, '../../packages', packageName);

console.log(`Creating new tool package: ${packageName}...`);

// 1. Generate package scaffold using Nx
try {
  execSync(`npx nx g @nx/js:lib packages/${packageName} --publishable --importPath=@lit-protocol/${packageName}`, {
    stdio: 'inherit'
  });
} catch (error) {
  console.error('Failed to generate package scaffold:', error);
  process.exit(1);
}

// 2. Copy configuration files from aw-tool-sign-ecdsa
const templatePackage = 'aw-tool-sign-ecdsa';
const templatePath = join(__dirname, '../../packages', templatePackage);
const configFiles = [
  'tsconfig.lib.json',
  'tsconfig.json',
  'tsconfig.spec.json',
  'package.json',
  'jest.config.ts',
  'eslint.config.cjs',
  '.gitignore',
  'README.md'
];

configFiles.forEach(file => {
  try {
    let content = readFileSync(join(templatePath, file), 'utf8');
    
    // Update package.json with new package name
    if (file === 'package.json') {
      content = content.replace(new RegExp(templatePackage, 'g'), packageName);
    }
    
    // Update README with new tool name
    if (file === 'README.md') {
      content = content.replace(new RegExp(templatePackage, 'g'), packageName)
                      .replace(/Sign ECDSA/g, className.split('-').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' '));
    }
    
    writeFileSync(join(packagePath, file), content);
  } catch (error) {
    console.warn(`Warning: Could not copy ${file}:`, error.message);
  }
});

// 3. Create source file structure
const srcPath = join(packagePath, 'src');
const libPath = join(srcPath, 'lib');
const litActionsPath = join(libPath, 'lit-actions');
const litActionsUtilsPath = join(litActionsPath, 'utils');
const testPath = join(packagePath, 'test');
const toolsPath = join(packagePath, 'tools');

[libPath, litActionsPath, litActionsUtilsPath, testPath, toolsPath].forEach(dir => {
  mkdirSync(dir, { recursive: true });
});

// Clean up Nx-generated files
try {
  unlinkSync(join(libPath, `${packageName}.ts`));
  unlinkSync(join(libPath, `${packageName}.spec.ts`));
} catch (error) {
  console.warn('Warning: Could not clean up Nx-generated files:', error.message);
}

// Copy ipfs.ts from template
copyFileSync(
  join(templatePath, 'src/lib/ipfs.ts'),
  join(libPath, 'ipfs.ts')
);

// Copy common utility files from aw-tool-erc20-transfer
const commonUtilFiles = [
  'check-lit-auth-address-is-delegatee.ts',
  'fetch-tool-policy-from-registry.ts',
  'get-pkp-info.ts',
  'get-pkp-tool-registry-contract.ts',
  'get-policy-parameters.ts',
  'network-config.ts'
];

const commonUtilsPackage = 'aw-tool-erc20-transfer';
const commonUtilsPath = join(__dirname, '../../packages', commonUtilsPackage, 'src/lib/lit-actions/utils');

try {
  commonUtilFiles.forEach(file => {
    const sourcePath = join(commonUtilsPath, file);
    const targetPath = join(litActionsUtilsPath, file);
    copyFileSync(sourcePath, targetPath);
  });
} catch (error) {
  console.warn('Warning: Could not copy utility files:', error.message);
}

// Create other required files with templates
const litActionPolicyTemplate = `import { PolicyConfig } from '@lit-protocol/aw-tool';

export function validatePolicy(policy: PolicyConfig): boolean {
  // Add your Lit Action policy validation logic here
  return true;
}`;

const litActionToolTemplate = `import { LitActionRequestContext } from '@lit-protocol/types';
import { validatePolicy } from './policy';

export async function litAction(context: LitActionRequestContext) {
  // Add your Lit Action code here
  // This is where your tool's core validation and execution logic goes
}`;

const policyTemplate = `import { PolicyConfig } from '@lit-protocol/aw-tool';

export interface ${className}PolicyConfig extends PolicyConfig {
  // Add your tool's policy configuration interface here
}

export function validatePolicy(policy: ${className}PolicyConfig): boolean {
  // Add your policy validation logic here
  return true;
}`;

const toolTemplate = `import { Tool, ToolConfig } from '@lit-protocol/aw-tool';
import { ${className}PolicyConfig, validatePolicy } from './policy';

export class ${className}Tool extends Tool {
  constructor(config: ToolConfig) {
    super(config);
  }

  // Add your tool's specific functionality here
}`;

const indexTemplate = `export * from './lib/tool';
export * from './lib/policy';`;

writeFileSync(join(litActionsPath, 'policy.ts'), litActionPolicyTemplate);
writeFileSync(join(litActionsPath, 'tool.ts'), litActionToolTemplate);
writeFileSync(join(libPath, 'policy.ts'), policyTemplate);
writeFileSync(join(libPath, 'tool.ts'), toolTemplate);
writeFileSync(join(srcPath, 'index.ts'), indexTemplate);

// Copy tools directory from template
try {
  execSync(`cp -r ${join(templatePath, 'tools/*')} ${toolsPath}`, { stdio: 'inherit' });
} catch (error) {
  console.warn('Warning: Could not copy tools directory:', error.message);
}

console.log(`
✨ Tool package created successfully!

Next steps:
1. Implement your tool's logic in:
   - src/lib/lit-actions/tool.ts (Lit Action code)
   - src/lib/lit-actions/policy.ts (Lit Action policy validation)
   - src/lib/policy.ts (Tool policy configuration)
   - src/lib/tool.ts (Tool functionality)

2. Register your tool in aw-tool-registry:
   - Import your tool in registry.ts
   - Add your package as a dependency

3. Run tests:
   pnpm test ${packageName}
`); 