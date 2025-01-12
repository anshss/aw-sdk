# Creating a New Agent Wallet Tool Package

This guide will walk you through the process of creating a new Agent Wallet tool package for the Lit Agent Wallet system.

## Initial Setup

1. Generate the package scaffold using Nx:
```bash
npx nx g @nx/js:lib packages/aw-tool-TOOL_NAME --publishable --importPath=@lit-protocol/aw-tool-TOOL_NAME
```

2. When prompted for project configuration options, select:
   - TypeScript for the compiler
   - ESLint for linting
   - Jest for testing

## Copy Required Configuration Files

Copy the following files from an existing tool package (e.g., aw-tool-sign-ecdsa) to your new package:

1. Configuration files:
   - `tsconfig.lib.json`
   - `tsconfig.json`
   - `package.json` (remember to update the tool name)
   - `jest.config.ts`
   - `eslint.config.js`
   - `.gitignore`

2. Copy the entire `tools` directory

3. Source files:
   - `src/lib/ipfs.ts`

## Implement Tool Logic

### Source Files Structure

Your tool package should have the following structure in the `src` directory:

```
src/
├── index.ts
└── lib/
    ├── ipfs.ts
    ├── lit-action.ts
    ├── policy.ts
    └── tool.ts
```

### Required Modifications

1. `src/lib/lit-action.ts`:
   - Write your custom Lit Action code that will run on Lit nodes
   - This is where your tool's core validation and execution logic goes
   - Examples can be found in the other tool packages

2. `src/lib/policy.ts`:
   - Define your tool's conditions for when execution should be allowed
   - Implement the validation functions for your conditions
   - Examples can be found in the other tool packages

3. `src/lib/tool.ts`:
   - This file needs to be almost completely rewritten for your tool
   - Implement your tool's specific functionality and logic
   - Examples can be found in the other tool packages

4. `src/index.ts`:
   - Edit this file to export your tool
   - Examples can be found in the other tool packages

## Register Your Tool

In the `aw-tool-registry` package:
1. Import your tool in `registry.ts` and call `registerTool` with your tool name and class
2. Add your tool package as a dependency in `package.json` using the workspace syntax